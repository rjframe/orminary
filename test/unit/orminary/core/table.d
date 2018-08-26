module unit.orminary.core.table;

import std.exception : assertThrown;
import orminary.core.table;

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
    assertThrown!Exception(s.opAssign("Hello."));
}

@("Ensure contraints on values")
unittest {
    Integer!(i => i > 12) age;
    Integer!((int i) { return i > 12; }) age2;
    age = 15;
    age2 = 15;

    assertThrown!Exception(age.opAssign(5),
            "Should not be able to assign value less than 13");
    assertThrown!Exception(age2.opAssign(5),
            "Should not be able to assign value less than 13");
}

