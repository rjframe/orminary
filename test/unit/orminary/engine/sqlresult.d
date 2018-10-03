module unit.orminary.engine.sqlresult;

import orminary.engine.sqlresult;
import orminary.core.model : NullValue;
import orminary.core.trace;

version(SqLite) {

@("OrminaryRow can contain all column data types")
unittest {
    struct TestRow {
        import d2sqlite3.results : ColumnData;
        ColumnData[] cols;
        alias cols this;
    }

    TestRow row() {
        import std.json : JSONValue;
        import d2sqlite3.results : ColumnData;
        TestRow r;
        r ~= ColumnData("A string.");
        r ~= ColumnData(JSONValue("JSON").toString());
        r ~= ColumnData(5);
        r ~= ColumnData(cast(short)7);
        r ~= ColumnData(10L);
        r ~= ColumnData(5.0f);
        r ~= ColumnData(10.0);
        r ~= ColumnData([1, 2, 3, 4]);
        r ~= ColumnData(null);
        return r;
    }

    auto ormRow = OrminaryRow(row());

    string print(T)(size_t idx) {
        import std.conv : text;
        return ormRow[idx].valueAs!T.text;
    }

    import std.math : approxEqual;
    assert(ormRow[0].valueAs!string == "A string.", print!string(0));
    // TODO: JSONValue.
    assert(ormRow[2].valueAs!int == 5, print!int(2));
    assert(ormRow[3].valueAs!short == 7, print!short(3));
    assert(ormRow[4].valueAs!long == 10, print!long(4));
    assert(ormRow[5].valueAs!float().approxEqual(5.0f), print!float(5));
    assert(ormRow[6].valueAs!double().approxEqual(10.0f), print!double(6));
    assert(ormRow[7].valueAs!(ubyte[]) == cast(ubyte[])[1, 2, 3, 4],
            print!(ubyte[])(7));
    assert(ormRow[8].valueAs!(typeof(NullValue)) == NullValue,
            print!(typeof(NullValue))(8));
}

} // version(SqLite)
