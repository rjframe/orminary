module integration.testsqlite;

version(SqLite) {

import std.conv : text;

import d2sqlite3;
import unit_threaded : Setup;

import orminary.core.model;
import orminary.core.expression;
import orminary.engine.sqlite;
import orminary.engine.sqlresult;
import orminary.core.trace;

SqLiteEngine sql;

@Setup
void setup() {
    sql = SqLiteEngine(":memory:");
    sql.db.run(
        "DROP TABLE IF EXISTS table1;
        CREATE TABLE table1 (
           id INT PRIMARY KEY NOT NULL,
           name VARCHAR(30)
        )"
    );
}

@("Create a table")
unittest {
    auto c = CreateTable("tablename",
            col!(Integer!())("id"),
            col!(String!())("name"),
            col!(String!(50))("addr")
        ).ifNotExists().primary("id");
    sql.query(c);
    assert(SqlResult(sql.db.execute("PRAGMA table_info(tablename);")).length > 0);
}

@("Create a table from another table")
unittest {
    auto first = CreateTable("first",
            col!(Integer!())("id"),
            col!(String!())("name"),
            col!(String!(50))("addr")
        ).ifNotExists().primary("id");
    sql.query(first);
    sql.db.execute("INSERT INTO first (id, name) VALUES (50, 'A');");
    sql.db.execute("INSERT INTO first (id, name) VALUES (500, 'B');");

    auto c = CreateTable("tablename",
            Select("id", "name").from("first").where("id".gt(100))
        );
    sql.query(c);

    auto result = SqlResult(sql.db.execute("SELECT id, name FROM tablename;"));
    assert(result.length == 1, result.length.text);
    assert(result[0][0].valueAs!int == 500);
    assert(result[0][1].valueAs!string == "B");
}

@("Create a table from a model")
unittest {
    @Model struct mytable {
        Integer!() id;
        String!() name;
    }
    sql.query(CreateTable(mytable()));
    sql.db.execute("INSERT INTO mytable (id, name) VALUES (50, 'A');");

    auto result = SqlResult(sql.db.execute("SELECT id, name FROM mytable;"));
    assert(result.length == 1, result.length.text);
    assert(result[0][0].valueAs!int == 50);
    assert(result[0][1].valueAs!string == "A");
}

@("Simple SELECT query")
unittest {
    auto table1 = sql.db.prepare("INSERT INTO table1 (id, name) VALUES (:id, :name)");
    with (table1) {
        bindAll(":name", "Favorite Person");
        execute();
        reset();
    }

    auto q = Select("name").from("table1").where("name".equals(`"Favorite Person"`));
    auto result = sql.query(q);
    assert(result.length == 1, result.length.text);
    assert(result[0][0].valueAs!string == "Favorite Person",
            result[0][0].valueAs!string);
}

@("Insert a row into a table")
unittest {
    @Model("table1") struct Table {
        Integer!() id;
        String!() name;
    }

    sql.query(Insert(1, "My Name").into!Table);
    auto res = sql.query(Select("id", "name").from("table1"));

    assert(res.length == 1);
    assert(res[0][0].valueAs!int == 1);
    assert(res[0][1].valueAs!string == "My Name");

    sql.query(Insert(value!"id"(2), value!"name"("Other Person")).into!Table);

    res = sql.query(Select("id", "name").from("table1"));
    assert(res.length == 2);
    assert(res[1][0].valueAs!int == 2);
    assert(res[1][1].valueAs!string == "Other Person");
}

@("Replace a row in the table")
unittest {
    @Model("table1") struct Table {
        Integer!() id;
        String!() name;
    }
    sql.query(Insert(1, "My Name").into!Table);
    sql.query(Replace(value!"id"(1), value!"name"("Other Person")).into!Table);

    auto res = sql.query(Select("id", "name").from("table1"));
    assert(res.length == 1);
    assert(res[0][0].valueAs!int == 1);
    assert(res[0][1].valueAs!string == "Other Person");
}

} // version(SqLite)
