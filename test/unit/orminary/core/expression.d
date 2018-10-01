module unit.orminary.core.expression;

import std.conv : text;

import orminary.core.trace;
import orminary.core.model;
import orminary.core.expression;

@("Construct a CREATE TABLE query object")
unittest {
    auto c = CreateTable("tablename",
            // I can't do this (yet): @primaryKey col!(Integer!())("id"),
            col!(Integer!())("id"),
            col!(String!())("name"),
            col!(Integer!(i => (i > 1900 && i < 2100)))("age")
        ).primary("id");

    assert(c.columns == [
            Column("id", "Integer"),
            Column("name", "String!(-1)"),
            Column("age", "Integer")
        ], c.columns.text);
    assert(c.primaryKey == "id");
}

@("Construct a CREATE TABLE IF NOT EXISTS query object")
unittest {
    auto c = CreateTable("tablename",
            col!(Integer!())("id"),
            col!(String!())("name"),
            col!(String!(50))("addr")
        ).ifNotExists().primary("id");

    assert(c.columns == [
            Column("id", "Integer"),
            Column("name", "String!(-1)"),
            Column("addr", "String!(50)")
        ], c.columns.text);
    assert(c.primaryKey == "id");
    assert(c.when == If.NotExists);
}

@("Construct a CREATE TABLE AS query object")
unittest {
    auto c = CreateTable("tablename",
            Select("id", "name").from("othertable").where("id".gt(100))
        );

    with (c.fromQuery) {
        assert(fields == ["id", "name"]);
        assert(tables == ["othertable"]);
        assert(filter.toString() == "id > 100");
    }
}

@("Construct a CREATE TABLE object from a model")
unittest {
    @Model struct mytable {
        Integer!() id;
        String!() name;
    }
    auto c = CreateTable(mytable());

    assert(c.name == "mytable");
    assert(c.columns == [
            Column("id", "Integer"),
            Column("name", "String!(-1)"),
        ], c.columns.text);
}

@("Construct a simple SELECT object")
unittest {
    auto s = Select("id", "name").from("mytable").where("id".gt(10));

    assert(s.fields == ["id", "name"]);
    assert(s.isDistinct == false);
    assert(s.tables == ["mytable"]);
    assert(s.filter.toString() == "id > 10");

    s = Select("id", "name").distinct().from("mytable").where("id".gt(10));
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

@("Support where condition clauses")
unittest {
    @Model struct MyTable { int id; string name; }
    auto s = Select("id", "name").from!MyTable.where("id".equals(10));

    assert(s.filter.toString() == "id == 10", s.filter.toString());
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

    auto s = Select("a", "b").from!T.groupBy("b", "a").having("SUM(a)".gt(1));
    assert(s.aggregateFilter().toString() == "SUM(a) > 1");
}
