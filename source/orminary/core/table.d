/** Manages database table abstractions. */
module orminary.core.table; @safe:

import std.json : JSONValue;

// TODO: Everything is Unicode; do I also want to support ASCII types?


/** UDA to specify that an object is a model/table row. */
struct Table {
    string name;
}

enum VarChar = -1;

/** Fixed-length or variable-length string. */
struct String(int length = VarChar, bool function(string) constraint = null) {
    private string val;

    void opAssign(string newValue) {
        static if (length != VarChar) {
            if (newValue.length > length)
                throw new Exception("TODO - invalid value");
        }
        static if (constraint) {
            if (! constraint(val))
                throw new Exception("TODO - invalid value");
        }

        val = newValue;
    }

    bool opEquals()(auto ref const typeof(this) other) {
        return val == other.val;
    }

    bool opEquals()(auto ref const string other) {
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

        ~ "    void opAssign(" ~ type ~ " newValue) {"
        ~ "        static if (constraint !is null) {"
        ~ "            if (! constraint(newValue))"
        ~ "                throw new Exception(`TODO - invalid value`);"
        ~ "        }"
        ~ "        val = newValue;"
        ~ "    }"

        ~ "    bool opEquals()(auto ref const typeof(this) other) {"
        ~ "        return val == other.val;"
        ~ "    }"

        ~ "    bool opEquals()(auto ref const " ~ type ~ " other) {"
        ~ "        return val == other;"
        ~ "    }"
        ~ "}";
}
