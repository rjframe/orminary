/** Build generic queries to transform into vendor-specific SQL. */
module orminary.core.expression; @safe:

struct Select {
    // TODO: distinct - flag.
    this(string[] cols ...) {
        _fields = cols.dup;
    }

    @property
    string[] fields() { return _fields; }

    @property
    string[] tables() { return _tables; }

    @property
    string filter() { return _filter; }

    @property
    bool isDistinct() { return _distinct; }

    private:

    string[] _fields;
    string[] _tables;
    string _filter;
    bool _distinct = false;
}

Select distinct(Select s) pure {
    s._distinct = true;
    return s;
}

Select from(Select s, string[] tables ...) pure {
    s._tables = tables;
    return s;
}

Select from(T...)(Select s, T tables) pure {
    import std.traits : hasUDA, getUDAs;
    import orminary.core.table : Table;

    static foreach (table; tables) {{
        static if (! hasUDA!(typeof(table), Table))
            throw new Exception("TODO - incorrect object");

        // TODO: Sanitize/transform name.
        auto name = getUDAs!(typeof(table), Table)[0].name;
        if (name.length == 0)
            name = typeof(table).stringof;
        s._tables ~= name;
    }}
    return s;
}

Select from(T...)(Select s) pure {
    import std.traits : hasUDA, getUDAs;
    import orminary.core.table : Table;

    static foreach(table; T) {{
        static if (! hasUDA!(table, Table))
            throw new Exception("TODO - incorrect object");

        auto name = getUDAs!(table, Table)[0].name;
        if (name.length == 0)
            name = table.stringof;

        s._tables ~= name;
    }}
    return s;
}

Select where(Select s, string filter) pure {
    s._filter = filter;
    return s;
}

struct Insert {}
