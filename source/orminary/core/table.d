/** Manages database table abstractions. */
module orminary.core.table; @safe:

// TODO: Better module/filename than table. Possibly types?

import std.json : JSONValue;

import orminary.core.trace;
// TODO: Everything is Unicode; do I also want to support ASCII types?
// I probably should.

/** UDA to specify that an object is a model/table. */
struct Table {
    private string _name = "";

    @property
    void name(string name) { _name = name; }

    // TODO: Sanitize/transform name.
    static string name(alias table)() {
        import std.traits : getUDAs, isType, isExpressionTuple;
        import orminary.core.table : Table;

        /* If the attribute is applied like "@Table struct t {}" then we end up
           with the UDA type itself, rather than an instance of it. */
        static if (isType!table)
            alias tableType = table;
         else
            alias tableType = typeof(table);

        static if (isExpressionTuple!(getUDAs!(tableType, Table)))
            return getUDAs!(tableType, Table)[0]._name;
         else
            return tableType.stringof;
    }
}

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
        "struct " ~ name ~ "(bool function(" ~ type ~ ") constraint = null) {"
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
