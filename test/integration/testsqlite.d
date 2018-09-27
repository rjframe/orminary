module integration.testsqlite;

version(SqLite) {

import std.conv : text;

import d2sqlite3;
import unit_threaded : Setup;

import orminary.core.expression;
import orminary.engine.sqlite;
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
    assert(result[0].value!string(0) == "Favorite Person", result[0].value!string(0));
}

} // version(SqLite)
