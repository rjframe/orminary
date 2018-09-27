/** Contains database-agnostic query result objects. */
module orminary.engine.sqlresult;

import sumtype;

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

    T value(T)(size_t index) if (! isNumeric!T) {
        return cols[index].tryMatch!(
                (T val) => val
            );
    }

    T value(T)(size_t index) if (isNumeric!T) {
        return cast(T) cols[index].tryMatch!(
                (long l) => l,
                (int i) => i,
                (short s) => s,
                (double d) => d,
                (float f) => f
            );
    }

    @property
    size_t length() { return cols.length; }

    private:

    ColumnData[] cols;
}
