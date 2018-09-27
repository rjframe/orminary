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
        foreach (i, table; select.tables) {
            q ~= table;
            if (i < select.tables.length-1)
                q ~= ", ";
        }

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

} // version(SqLite)
