module unit.orminary.engine.sqlite;

version(SqLite) {

import unit_threaded : Setup;

import orminary.core.model;
import orminary.core.expression;
import orminary.engine.sqlite;

SqLiteEngine sql;

@Setup
void setup() {
    sql = SqLiteEngine(":memory:");
}

@("Build a CREATE TABLE statement")
unittest {
    auto c = CreateTable("tablename",
            col!(Integer!())("id"),
            col!(String!())("name"),
            col!(String!(50))("addr")
        ).ifNotExists().primary("id");

    auto q = sql.buildQuery(c);
    assert(q == "CREATE TABLE IF NOT EXISTS tablename (id INTEGER PRIMARY KEY, "
        ~ "name TEXT, addr TEXT)",
        q);
}

@("Build a CREATE TABLE AS statement")
unittest {
    auto c = CreateTable("tablename",
            Select("id", "name").from("othertable").where("id".gt(100))
        );

    auto q = sql.buildQuery(c);
    assert(q == "CREATE TABLE tablename AS SELECT id, name FROM othertable WHERE id > 100;",
        q);
}

@("Build a simple SELECT statement")
unittest {
    @Model struct a { Integer!() b; }
    auto s = Select("b").from!a.where("b".gt(10));

    assert(sql.buildQuery(s) == "SELECT b FROM a WHERE b > 10;",
            sql.buildQuery(s));
}

@("SELECT with GROUP BY")
unittest {
    @Model struct T { Integer!() a; String!() b; }
    auto s = Select("a", "b").from!T.groupBy("b", "a");

    assert(sql.buildQuery(s) == "SELECT a, b FROM T GROUP BY b, a;",
            sql.buildQuery(s));
}

@("SELECT with HAVING")
unittest {
    @Model struct T { Integer!() a; String!() b; }
    auto s = Select("a", "b").from!T.groupBy("b", "a").having("SUM(a)".gt(10));

    assert(sql.buildQuery(s) == "SELECT a, b FROM T GROUP BY b, a HAVING SUM(a) > 10;",
            sql.buildQuery(s));
}

@("Build an INSERT statement")
unittest {
    @Model("table1") struct Table {
        Integer!() id;
        String!() name;
    }

    auto i = Insert(1, "My Name").into!Table;
    assert(sql.buildQuery(i) == `INSERT INTO table1 VALUES (1, "My Name");`,
            sql.buildQuery(i));
}

} // version(SqLite)
