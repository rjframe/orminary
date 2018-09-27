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

    import std.math : approxEqual;
    assert(ormRow.value!string(0) == "A string.");
    // TODO: JSONValue.
    assert(ormRow.value!int(2) == 5);
    assert(ormRow.value!short(3) == 7);
    assert(ormRow.value!long(4) == 10);
    assert(ormRow.value!float(5).approxEqual(5.0f));
    assert(ormRow.value!double(6).approxEqual(10.0));
    assert(ormRow.value!(ubyte[])(7) == cast(ubyte[])[1, 2, 3, 4]);
    assert(ormRow.value!(typeof(NullValue))(8) == NullValue);
}

} // version(SqLite)
