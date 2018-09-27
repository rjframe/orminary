/** Build generic queries to transform into vendor-specific SQL.

    This is a namespace-polluting module; if you use this directly, you will
    probably want to use static or renamed imports; e.g.,

    ---
    import sql = orminary.core.expression;
    auto query = sql.Select('row').from(MyTable);
    ---

*/
module orminary.core.expression; @safe:

import std.json : JSONValue;

import sumtype;

import orminary.core.model : NullValue;
import orminary.core.trace;

// TODO: constraints are not placed on the table; at least not yet.
// I need to allow declaring CreateTable constraints differently than model
// constraints.
struct CreateTable {
    this(string name, Column[] cols...) {
        this.name = name;
        this.cols = cols.dup;
    }

    @property
    auto columns() pure const { return cols; }

    @property
    auto when() pure const { return _when; }

    @property
    auto primaryKey() pure const { return _primaryKey; }

    private:

    Column[] cols;
    string name;
    If _when = If.Always;
    string _primaryKey;
}

const(Column) col(alias Type)(in string name) pure {
    trace("col type: ", Type.stringof);

    // Remove the constraint.
    enum typeString = {
        import std.string : split;
        auto ident = Type.stringof.split('!');
        if (ident[0] == "String") {
            auto stringSubType = ident[1].split(',')[0];
            return ident[0] ~ "!" ~ stringSubType ~ ")";
        } else return ident[0];
    }();

    return Column(name, typeString);
}

struct Column {
    string name;
    string type;
}

alias ColumnData = SumType!(
        string,
        JSONValue,
        int,
        short,
        long,
        float,
        double,
        ubyte[],
        typeof(NullValue)
    );

/** Used to specify when to create a table. */
enum If {
    Always,   // Not expected to be called by user code.
    NotExists
}

CreateTable primary(CreateTable t, in string name) pure {
    // TODO: ensure name is in the list of tables.
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

Select distinct(Select s) pure {
    s._distinct = true;
    return s;
}

Select from(Select s, const(string[]) tables...) pure {
    s._tables = tables.dup;
    return s;
}

Select from(T...)(Select s, const(T) tables) pure {
    import std.traits : hasUDA;
    import orminary.core.model : Model;

    static foreach (table; tables) {{
        static if (! hasUDA!(typeof(table), Model))
            throw new Exception("TODO - incorrect object");

        s._tables ~= Model.name!table;
    }}
    return s;
}

Select from(T...)(Select s) pure {
    import std.traits : hasUDA;
    import orminary.core.model : Model;

    static foreach(table; T) {{
        static if (! hasUDA!(table, Model))
            throw new Exception("TODO - incorrect object");
        else
            s._tables ~= Model.name!table;
    }}
    return s;
}

Select where(Select s, in Filter filter) pure {
    s._filter = filter;
    return s;
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

struct Insert {}


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
