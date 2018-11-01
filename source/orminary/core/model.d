/** Manages database model abstractions. */
module orminary.core.model; @safe:

import std.json : JSONValue;

import orminary.core.exception;
import orminary.core.trace;
// TODO: Everything is Unicode; do I also want to support ASCII types?
// I probably should.

/** UDA to specify that an object is a row/model. */
struct Model {
    private string _name = "";

    @property
    void name(string name) { _name = name; }

    // TODO: Sanitize/transform name.
    static string getNameOf(alias model)() {
        import std.traits : getUDAs, isType, isExpressionTuple;

        /* If the attribute is applied like "@Model struct t {}" then we end up
           with the UDA type itself, rather than an instance of it. */
        static if (isType!model)
            alias modelType = model;
         else
            alias modelType = typeof(model);

        static if (isExpressionTuple!(getUDAs!(modelType, Model)))
            return getUDAs!(modelType, Model)[0]._name;
         else
            return modelType.stringof;
    }
}

private struct _NullValue {}
enum NullValue = _NullValue();

enum VarChar = -1;

/** Fixed-length or variable-length string. */
struct String(int length = VarChar, bool function(string) constraint = null) {
    private string val;

    void opAssign(const(char[]) newValue) {
        static if (length != VarChar) {
            if (newValue.length > length)
                throw new InvalidData(newValue, "Given string is too long");
        }
        static if (constraint) {
            if (! constraint(val))
                throw new InvalidData(newValue, "Value fails constraint");
        }

        val = newValue.dup;
    }

    bool opEquals()(auto ref const(typeof(this)) other) {
        return val == other.val;
    }

    bool opEquals()(auto ref const(string) other) {
        return val == other;
    }
}

/** Variable-length string.

    Uses NVARCHAR or similar on the database side.
*/
mixin(GenerateOrmType("Text", "string"));
// TODO: Versioned vibe json type?
mixin(GenerateOrmType("Json", "JSONValue"));
mixin(GenerateOrmType("Integer", "int"));
mixin(GenerateOrmType("SmallInteger", "short"));
mixin(GenerateOrmType("BigInteger", "long"));
mixin(GenerateOrmType("Float", "float"));
mixin(GenerateOrmType("Double", "double"));

/*TODO:
mixin(GenerateOrmType("Decimal", ""));
mixin(GenerateOrmType("Date", ""));
mixin(GenerateOrmType("DateTime", ""));
mixin(GenerateOrmType("Time", ""));
mixin(GenerateOrmType("Binary", ""));

// Experiment...
enum serializeAs { Xml, Json }
struct Serialize(T, serializeAs format) {
}
*/

string GenerateOrmType(string name, string type) {
    return
        "struct " ~ name ~ "(bool function(" ~ type ~ ") @safe constraint = null) {"
        ~ "    private " ~ type ~ " val;"

        ~ "    void opAssign(const(" ~ type ~ ") newValue) {"
        ~ "        static if (constraint !is null) {"
        ~ "            if (! constraint(newValue))"
        ~ "                throw new InvalidData(newValue, `Value fails constraint`);"
        ~ "        }"
        ~ "        val = newValue;"
        ~ "    }"

        ~ "    bool opEquals()(auto ref const(typeof(this)) other) {"
        ~ "        return val == other.val;"
        ~ "    }"

        ~ "    bool opEquals()(auto ref const(" ~ type ~ ") other) {"
        ~ "        return val == other;"
        ~ "    }"
        ~ "}";
}

struct OrminaryColumn {
    import std.conv : text;
    import std.traits : isNumeric, isSomeString;
    import sumtype;

    this(T)(in T data) if (! isSomeString!T) {
        this._toString = data.text; // This is ugly.
        this.data = data;
    }

    this(T)(in T data) if (isSomeString!T) {
        this._toString = `"` ~ data ~ `"`; // This is ugly.
        this.data = data;
    }

    const(T) valueAs(T)() inout if (! isNumeric!T) {
        scope(failure) throw new InvalidType!T();
        return data.tryMatch!(
                (const(T) val) => val
            );
    }

    const(T) valueAs(T)() inout if (isNumeric!T) {
        scope(failure) throw new InvalidType!T();
        return cast(T) data.tryMatch!(
                (long l) => l,
                (int i) => i,
                (short s) => s,
                (double d) => d,
                (float f) => f
            );
    }

    string toString() const {
        return _toString;
    }

    private:

    auto data = SumType!(
            string,
            JSONValue,
            int,
            short,
            long,
            float,
            double,
            ubyte[],
            typeof(NullValue)
        )();

    string _toString;
}

struct OrminaryRow {
    const(OrminaryColumn) opIndex(in size_t idx) {
        return cols[idx];
    }

    ref typeof(this) opOpAssign(string op)(in OrminaryColumn value)
            if (op == "~") {

        cols ~= value;
        return this;
    }

    size_t opDollar() { return cols.length; }

    @property
    size_t length() { return cols.length; }

    private:

    OrminaryColumn[] cols;
}
