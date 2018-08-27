module unit.orminary.core.expression;

import orminary.core.expression;

@("Construct a simple SELECT object")
unittest {
    auto s = Select("id", "name").from("mytable").where("id > 10");

    import std.stdio;writeln(s);
}

@("Pass table objects to the SELECT query")
unittest {
    import orminary.core.table;

    @Table()
    struct T {
        Integer!() a;
    }

    @Table("other_name")
    struct U {
        Integer!() a;
    }

    auto t = T();
    auto u = U();
    auto s = Select("a").from(t, u);
    import std.stdio;writeln(s);
}
