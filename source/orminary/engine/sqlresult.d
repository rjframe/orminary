/** Contains database-agnostic query result objects. */
module orminary.engine.sqlresult;

import std.traits : isNumeric;

// TODO: Can I remove the SQL DB dependencies and move this into core?
// It would be nice for the ORM definitions to be in core, with the DB->ORM
// marshalling handled by each engine.

import orminary.core.model : NullValue;
import orminary.core.expression : ColumnData;
import orminary.core.trace;

struct SqlResult {
    version(SqLite) {
        import d2sqlite3.results : ResultRange;
        this(ResultRange queryResult) {
            foreach (row; queryResult)
                rows ~= OrminaryRow(row);
        }
    }

    @property
    size_t length() { return rows.length; }

    OrminaryRow opIndex(size_t index) {
        return rows[index];
    }

    private:

    OrminaryRow[] rows;
}

struct OrminaryRow {
    import std.traits : isNumeric;

    version(SqLite) {
        import d2sqlite3.database : SqliteType;
        import d2sqlite3.results : SqLiteRow = Row;
        this(ROW = SqLiteRow)(ROW r) {
            foreach (col; r) {
                final switch (col.type) {
                    case SqliteType.INTEGER:
                        cols ~= ColumnData(col.as!long);
                        break;
                    case SqliteType.FLOAT:
                        cols ~= ColumnData(col.as!double);
                        break;
                    case SqliteType.TEXT:
                        cols ~= ColumnData(col.as!string);
                        break;
                    case SqliteType.BLOB:
                        cols ~= ColumnData(col.as!(ubyte[]));
                        break;
                    case SqliteType.NULL:
                        cols ~= ColumnData(NullValue);
                        break;
                }
            }
        }
    } // version(SqLite)

    const(ColumnData) opIndex(in size_t idx) {
        return cols[idx];
    }

    @property
    size_t length() { return cols.length; }

    private:

    ColumnData[] cols;
}

const(T) valueAs(T)(ColumnData c) if (! isNumeric!T) {
    import sumtype : tryMatch;
    return c.tryMatch!(
            (T val) => val
        );
}

const(T) valueAs(T)(ColumnData c) if (isNumeric!T) {
    import sumtype : tryMatch;
    return cast(T) c.tryMatch!(
            (long l) => l,
            (int i) => i,
            (short s) => s,
            (double d) => d,
            (float f) => f
        );
}
