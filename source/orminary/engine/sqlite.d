module orminary.engine.sqlite;

version(SqLite) {

import orminary.core.trace;
import orminary.core.expression;
import orminary.engine.sqlresult;

// TODO: Use concepts to verify engine APIs.
// TODO: All queries should be parameterized.

struct SqLiteEngine {
    import d2sqlite3 : Database;

    this(string connectionString) {
        connectTo(connectionString);
    }

    void connectTo(string connectionString) {
        if (this.isInitialized)
            _db.close();

        _db = Database(connectionString);
        isInitialized = true;
    }

    SqlResult query(const(Select) select) {
        // TODO: Validation.
        auto q = buildQuery(select);
        return SqlResult(db.execute(q));
    }

    void query(const(CreateTable) createTable) {
        // TODO: Validation.
        db.execute(buildQuery(createTable));
    }

    static string buildQuery(const(CreateTable) createTable) pure {
        import std.array : appender;

        auto q = appender!string("CREATE TABLE ");
        if (createTable.when == If.NotExists)
            q ~= "IF NOT EXISTS ";

        q ~= createTable.name;
        q ~= " ";

        /* TODO: Support multiple primary keys(?):
            CREATE...
                name TYPE,
                name2 TYPE2,
                PRIMARY KEY (name, name2)
        */
        if (createTable.columns.length) {
            q ~= "(";
            for (size_t i = 0; i < createTable.columns.length; ++i) {
                q ~= createTable.columns[i].name;
                q ~= " ";
                q ~= createTable.columns[i].type.fixTypeName();

                if (createTable.columns[i].name == createTable.primaryKey)
                    q ~= " PRIMARY KEY";

                if (i < createTable.columns.length - 1)
                    q ~= ", ";
            }
            q ~= ")";
        } else {
            q ~= "AS ";
            q ~= SqLiteEngine.buildQuery(createTable.fromQuery());
        }
        return q.data;
    }

    static string buildQuery(const(Select) select) pure {
        import std.array : appender;
        import std.algorithm.iteration : joiner;

        auto q = appender!string("SELECT ");

        if (select.isDistinct) {
            q ~= " DISTINCT ";
        }

        trace("fields");
        q ~= select.fields.dup().joiner(", ");

        q ~= " FROM ";
        trace("tables");
        q ~= select.tables.dup().joiner(", ");

        if (select.filter.isSet) {
            trace("filter");
            q ~= " WHERE ";
            q ~= select.filter.toString();
        }

        if (select.groups) {
            trace("groups");
            q ~= " GROUP BY ";
            q ~= select.groups.dup().joiner(", ");
        }

        if (select.aggregateFilter.isSet) {
            trace("having");
            q ~= " HAVING ";
            q ~= select.aggregateFilter.toString();
        }

        q ~= ";";
        return q.data;
    }

    SqlResult query(R)(const(Insert) insert) {
        assert(0);
    }

    /** Provides access to the underlying d2sqlite3 Database object.

        If you find that you need this, file an issue as the ORM should likely
        support your task without the need for making direct database queries.
    */
    deprecated("db() is provided in pre-release to ensure you can do what you need to do. Please file a feature request.")
    @property Database db() {
        if (isInitialized)
            return _db;
        else
            throw new Exception("TODO - must connect to DB first");
    }

    private:

    Database _db;
    bool isInitialized = false;
}

private:

string fixTypeName(in string type) pure
    out(ret) {
        assert(ret.length > 0, "Implement type: " ~ type);
    } body {

    import std.algorithm.searching : startsWith, endsWith;
    return type == "Float" ? "REAL"
        : type == "Double" ? "REAL"
        : type.endsWith("Integer") ? "INTEGER"
        : type.startsWith("String") ? "TEXT"
        : "";
}

} // version(SqLite)
