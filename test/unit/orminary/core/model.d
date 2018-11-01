module unit.orminary.core.model;

import std.exception : assertThrown;
import orminary.core.model;
import orminary.core.exception;

@("Construct and assign ORM values")
unittest {
    Integer!() i;
    i = 10;
    assert(i == 10);
}

@("Construct and assign variable-length string values")
unittest {
    String!() s;
    s = "Hello.";
    assert(s == "Hello.");
}

@("Construct and assign fixed-length string values")
unittest {
    String!10 s;
    s = "Hello.";
    assert(s == "Hello.");
}

@("Cannot assign a string of greater length than its maximum")
unittest {
    String!5 s;
    assertThrown!InvalidData(s.opAssign("Hello."));
}

@("Ensure contraints on values")
unittest {
    Integer!(i => i > 12) age;
    Integer!((int i) { return i > 12; }) age2;
    age = 15;
    age2 = 15;

    assertThrown!InvalidData(age.opAssign(5),
            "Should not be able to assign value less than 13");
    assertThrown!InvalidData(age2.opAssign(5),
            "Should not be able to assign value less than 13");
}

@("OrminaryRow can contain all column data types")
unittest {
    import std.math : approxEqual;

    auto ormRow = {
        import std.json : JSONValue;
        OrminaryRow r;

        r ~= OrminaryColumn("A string.");
        r ~= OrminaryColumn(JSONValue("JSON").toString()); // TODO: Forget the toString().
        r ~= OrminaryColumn(5);
        r ~= OrminaryColumn(cast(short)7);
        r ~= OrminaryColumn(10L);
        r ~= OrminaryColumn(5.0f);
        r ~= OrminaryColumn(10.0);
        r ~= OrminaryColumn(cast(ubyte[]) [1, 2, 3, 4]);
        r ~= OrminaryColumn(NullValue);

        return r;
    }();

    string print(T)(size_t idx) {
        import std.conv : text;
        return ormRow[idx].valueAs!T.text;
    }

    assert(ormRow[0].valueAs!string == "A string.", print!string(0));
    // TODO: JSONValue.
    assert(ormRow[2].valueAs!int == 5, print!int(2));
    assert(ormRow[3].valueAs!short == 7, print!short(3));
    assert(ormRow[4].valueAs!long == 10, print!long(4));
    assert(ormRow[5].valueAs!float().approxEqual(5.0f), print!float(5));
    assert(ormRow[6].valueAs!double().approxEqual(10.0f), print!double(6));
    assert(ormRow[7].valueAs!(ubyte[]) == cast(ubyte[])[1, 2, 3, 4],
            print!(ubyte[])(7));
    assert(ormRow[8].valueAs!(typeof(NullValue)) == NullValue,
            print!(typeof(NullValue))(8));
}

@("Throw on attempt to access a column's data with incorrect type")
unittest {
    auto c = OrminaryColumn(5000);
    assertThrown!(InvalidType!string)(c.valueAs!string);
}
