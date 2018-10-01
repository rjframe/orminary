/** Manages database model abstractions. */
module orminary.core.model; @safe:

// TODO: Better module/filename than model. Possibly types?

import std.json : JSONValue;

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
                throw new Exception("TODO - invalid value");
        }
        static if (constraint) {
            if (! constraint(val))
                throw new Exception("TODO - invalid value");
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
        ~ "                throw new Exception(`TODO - invalid value`);"
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
