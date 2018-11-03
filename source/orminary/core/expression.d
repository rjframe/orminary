/** Build generic queries to transform into vendor-specific SQL.

    This is a namespace-polluting module; if you use this directly, you will
    probably want to use static or renamed imports; e.g.,

    ---
    import sql = orminary.core.expression;
    auto query = sql.Select('row').from(MyTable);
    ---

*/
module orminary.core.expression; @safe:

import std.traits : hasMember;
import std.json : JSONValue;

import orminary.core.model : Model, NullValue;
import orminary.core.exception;
import orminary.core.trace;

// TODO: constraints are not placed on the table.
// I need to allow declaring CreateTable constraints differently than model
// constraints.
struct CreateTable {
    this(in string name, in CreateTableColumn[] cols...) {
        this._name = name;
        this.cols = cols.dup;
    }

    this(string name, Select select) {
        this._name = name;
        this._fromQuery = select;
    }

    this(M)(M model) {
        import std.traits : hasUDA, Fields, FieldNameTuple;
        import orminary.core.model : Model;

        alias T = typeof(model);
        static if (! hasUDA!(T, Model))
            throw new Exception("TODO - incorrect object");
        this._name ~= Model.getNameOf!model;

        alias memberNames = FieldNameTuple!T;
        static foreach (i, memberType; Fields!T) {
            cols ~= col!memberType(memberNames[i]);
        }
    }

    @property
    auto name() pure const { return _name; }

    @property
    auto columns() pure const { return cols; }

    @property
    auto fromQuery() pure const { return _fromQuery; }

    @property
    auto when() pure const { return _when; }

    // TODO: Support multiple primary keys(?)
    @property
    auto primaryKey() pure const { return _primaryKey; }

    private:

    // One or the other of these will be used.
    CreateTableColumn[] cols;
    Select _fromQuery;

    string _name;
    If _when = If.Always;
    string _primaryKey;
}

const(CreateTableColumn) col(alias Type)(in string name) pure {
    // Remove the constraint.
    enum typeString = {
        import std.string : split;
        auto ident = Type.stringof.split('!');
        if (ident[0] == "String") {
            auto stringSubType = ident[1].split(',')[0];
            return ident[0] ~ "!" ~ stringSubType ~ ")";
        } else return ident[0];
    }();

    return CreateTableColumn(name, typeString);
}

struct CreateTableColumn {
    string name;
    string type;
}

/** Used to specify when to create a table. */
enum If {
    Always,   // Not expected to be called by user code.
    NotExists
}

CreateTable primary(CreateTable t, in string name) pure {
    bool found = false;
    foreach (col; t.cols) {
        if (col.name == name) {
            found = true;
            break;
        }
    }
    if (! found) throw new Exception("TODO - invalid primary key");

    t._primaryKey = name;
    return t;
}

CreateTable ifNotExists(CreateTable t) pure {
    t._when = If.NotExists;
    return t;
}

struct Select {
    this(const(string[]) cols ...) {
        _fields = cols.dup;
    }

    @property
    const(string[]) fields() pure const { return _fields; }

    @property
    const(string[]) tables() pure const { return _tables; }

    @property
    const(Filter) filter() pure const { return _filter; }

    @property
    const(string[]) groups() pure const { return _groups; }

    @property
    const(bool) isDistinct() pure const { return _distinct; }

    // HAVING clause.
    @property
    const(Filter) aggregateFilter() pure const { return _aggregateFilter; }

    private:

    string[] _fields;
    string[] _tables;
    string[] _groups;
    Filter _filter;
    Filter _aggregateFilter;
    bool _distinct = false;
}

struct Delete {

    @property
    const(string[]) tables() pure const { return _tables; }

    @property
    const(Filter) filter() pure const { return _filter; }

    private:

    string[] _tables;
    Filter _filter;
}

Select distinct(Select s) pure {
    s._distinct = true;
    return s;
}

Q from(Q)(Q q, const(string[]) tables...) if (hasMember!(Q, "_tables")) {
    q._tables = tables.dup;
    return q;
}

Q from(Q, T...)(Q q, const(T) tables) if (hasMember!(Q, "_tables")) {
    import std.traits : hasUDA;

    static foreach (table; tables) {{
        static if (! hasUDA!(typeof(table), Model))
            throw new NotAModelObject(typeof(table));

        q._tables ~= Model.getNameOf!table;
    }}
    return q;
}

Select from(T...)(Select q) {
    return from!(Select, T)(q);
}

Delete from(T...)(Delete q) {
    return from!(Delete, T)(q);
}

private Q from(Q, T...)(Q q) if (hasMember!(Q, "_tables")) {
    import std.traits : hasUDA;
    import orminary.core.model : Model;

    static foreach(table; T) {{
        static if (! hasUDA!(table, Model))
            throw new NotAModelObject(typeof(table));
        else
            q._tables ~= Model.getNameOf!table;
    }}
    return q;
}

Q where(Q)(Q q, in Filter filter) if (hasMember!(Q, "_filter")) {
    q._filter = filter;
    return q;
}

mixin(generateConditional("equals", "equalTo"));
mixin(generateConditional("lessThan", "lessThan"));
mixin(generateConditional("lessThanEq", "lessThanOrEqualTo"));
mixin(generateConditional("greaterThan", "greaterThan"));
mixin(generateConditional("greaterThanEq", "greaterThanOrEqualTo"));
alias eq = equals;
alias lt = lessThan;
alias lte = lessThanEq;
alias gt = greaterThan;
alias gte = greaterThanEq;

Select groupBy(Select s, in string[] groups...) pure {
    s._groups = groups.dup;
    return s;
}

Select having(Select s, in Filter aggregateFilter) pure {
    s._aggregateFilter = aggregateFilter;
    return s;
}

template InsertAndReplaceConstructors() {
    import std.typecons : Tuple;
    import orminary.core.model : OrminaryColumn;

    // The into() function validates these.
    this(T...)(in T values) {
        foreach (val; values) {
            columnArray ~= OrminaryColumn(val);
        }
    }

    // The into() function validates these.
    this(in Tuple!(string, OrminaryColumn)[] values...) {
        foreach (val; values) {
            columnMap[val[0]] = val[1];
        }
    }
}

struct Insert {
    mixin InsertAndReplaceConstructors;

    @property
    string table() pure const { return _table; }

    const(OrminaryColumn) opIndex(in size_t idx) const {
        if (idx < columnArray.length)
            return columnArray[idx];
        else
            throw new RangeViolation(idx, columnArray.length);
    }

    const(OrminaryColumn) opIndex(in string key) const {
        if (key in columnMap)
            return columnMap[key];
        else
            throw new ColumnDoesNotExist("Cannot find column", key);
    }

    size_t opDollar() pure const { return length; }

    @property
    size_t length() pure const {
        return hasNamedColumns ? columnMap.length : columnArray.length;
    }

    @property
    bool hasNamedColumns() pure const { return columnMap.length > 0; }

    @property
    string[] rows() pure const {
        import std.array : array;
        return columnMap.byKey().array;
    }

    private:

    // One or the other will be in use, depending on the constructor.
    OrminaryColumn[string] columnMap; // Name, value.
    OrminaryColumn[] columnArray;     // Just values.

    string _table;
}

auto value(alias name, T)(in T val) pure {
    import std.typecons : tuple;
    import orminary.core.model : OrminaryColumn;
    return tuple(name, OrminaryColumn(val));
}

struct Replace {
    mixin InsertAndReplaceConstructors;

    Insert insert;
    alias insert this;
}

INS into(T, INS)(INS i) if (is(INS == Insert) || is(INS == Replace)) {
    import std.traits : hasUDA, FieldNameTuple;
    import orminary.core.model : Model;
    import orminary.core.exception;

    static if (! hasUDA!(T, Model))
        throw new InvalidType!(T, Model);
    else
        i._table ~= Model.getNameOf!T;

    // We cannot actually validate fields in the Insert constructor, because we
    // don't know what table we're inserting into at the time. So we do it here.
    enum fields = FieldNameTuple!T;
    if (i.hasNamedColumns) {
        foreach (col; i.columnMap.byKey()) {
            bool found = false;
            foreach (field; fields) {
                if (col == field) {
                    found = true;
                    break;
                }
            }
            if (!found)
                throw new ColumnDoesNotExist(
                        "The specified column name is invalid", col);
        }
    } else {
        // TODO: Check data types.
        if (i.columnArray.length != fields.length)
            throw new MissingData("You must insert into all fields",
                    fields.length);
    }

    return i;
}

private:

/** Filter options the WHERE condition of a SQL statement. */
enum SqlFilterOp : string {
    equalTo = " == ",
    lessThan = " < ",
    lessThanOrEqualTo = " <= ",
    greaterThan = " > ",
    greaterThanOrEqualTo = " >= "
}

/** Contains WHERE clause data. */
struct Filter {
    string field;
    SqlFilterOp op;
    string value;

    this(T)(in string field, in SqlFilterOp op, in T value) {
        import std.conv : text;
        this.field = field;
        this.op = op;
        this.value = value.text;
    }

    @property
    string toString() pure const { return field ~ op ~ value; }

    @property
    bool isSet() pure const {
        return field.length && value.length;
    }
}

/** Generates the conditional functions. */
string generateConditional(string name, string op) {
    return
        "auto " ~ name ~ "(T)(in string field, in T value) {" ~
            "return Filter(field, SqlFilterOp." ~ op ~ ", value);" ~
        "}";
}
