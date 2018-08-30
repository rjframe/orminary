/** Build generic queries to transform into vendor-specific SQL. */
module orminary.core.expression; @safe:

struct Select {
    // TODO: distinct - flag.
    this(const(string[]) cols ...) {
        _fields = cols.dup;
    }

    @property
    const(string[]) fields() pure const { return _fields; }

    @property
    const(string[]) tables() pure const { return _tables; }

    @property
    const(string) filter() pure const { return _filter; }

    @property
    const(string[]) groups() pure const { return _groups; }

    @property
    const(bool) isDistinct() pure const { return _distinct; }

    // HAVING parameter.
    @property
    const(string) aggregateFilter() pure const { return _aggregateFilter; }

    private:

    string[] _fields;
    string[] _tables;
    string[] _groups;
    string _filter;
    string _aggregateFilter;
    bool _distinct = false;
}

Select distinct(Select s) pure {
    s._distinct = true;
    return s;
}

Select from(Select s, const(string[]) tables ...) pure {
    s._tables = tables.dup;
    return s;
}

Select from(T...)(Select s, const(T) tables) pure {
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

Select where(Select s, const(string) filter) pure {
    s._filter = filter;
    return s;
}

Select groupBy(Select s, const(string[]) groups...) {
    s._groups = groups.dup;
    return s;
}

Select having(Select s, const(string) aggregateFilter) pure {
    s._aggregateFilter = aggregateFilter;
    return s;
}

struct Insert {}
