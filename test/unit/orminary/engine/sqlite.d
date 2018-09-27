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

} // version(SqLite)
