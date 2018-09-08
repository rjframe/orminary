module unit.orminary.core.expression;

import std.conv : text;

import orminary.core.model;
import orminary.core.expression;

@("Construct a simple SELECT object")
unittest {
    auto s = Select("id", "name").from("mytable").where("id > 10");

    assert(s.fields == ["id", "name"]);
    assert(s.isDistinct == false);
    assert(s.tables == ["mytable"]);
    assert(s.filter == "id > 10");

    s = Select("id", "name").distinct().from("mytable").where("id > 10");
    assert(s.isDistinct == true);
}

@("Pass table objects to the SELECT query")
unittest {
    @Model struct T { Integer!() a; }

    @Model("other_name") struct U { Integer!() a; }

    auto t = T();
    auto u = U();
    auto s = Select("a").from(t, u);

    assert(s.tables == ["T", "other_name"], s.tables.text);
}

@("Pass table types to the SELECT query")
unittest {
    @Model struct T { Integer!() a; }
    @Model("other_name") struct U { Integer!() a; }

    auto s = Select("a").from!(T, U);
    assert(s.tables == ["T", "other_name"], s.tables.text);
}

@("Add a GROUP By clause")
unittest {
    @Model struct T { Integer!() a; String!() b; }

    auto s = Select("a", "b").from!T.groupBy("b", "a");
    assert(s.groups() == ["b", "a"]);
}

@("Add a HAVING clause")
unittest {
    @Model struct T { Integer!() a; String!() b; }

    auto s = Select("a", "b").from!T.groupBy("b", "a").having("SUM(a) > 1");
    assert(s.aggregateFilter() == "SUM(a) > 1");
}
