/** Contains database-agnostic query result objects. */
module orminary.engine.sqlresult;

import std.traits : isNumeric;

// TODO: Can I remove the SQL DB dependencies and move this into core?
// It would be nice for the ORM definitions to be in core, with the DB->ORM
// marshalling handled by each engine.

import orminary.core.model;
import orminary.core.trace;

import d2sqlite3.results : ColumnData, ResultRange;

struct SqlResult {
    version(SqLite) {
        this(ResultRange queryResult) {
            foreach (row; queryResult) {
                OrminaryRow ormRow;
                foreach (col; row) {
                    ormRow ~= convert(col);
                }
                rows ~= ormRow;
            }
        }
    }

    @property
    size_t length() const { return rows.length; }

    OrminaryRow opIndex(size_t index) {
        return rows[index];
    }

    private:

    OrminaryRow[] rows;
}

private:

auto convert(ColumnData col) {
    import d2sqlite3.database : SqliteType;

    final switch (col.type) {
        case SqliteType.INTEGER:
            return OrminaryColumn(col.as!long);
        case SqliteType.FLOAT:
            return OrminaryColumn(col.as!double);
        case SqliteType.TEXT:
            return OrminaryColumn(col.as!string);
        case SqliteType.BLOB:
            return OrminaryColumn(col.as!(ubyte[]));
        case SqliteType.NULL:
            return OrminaryColumn(NullValue);
    }
}
