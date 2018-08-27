/** Build generic queries to transform into vendor-specific SQL. */
module orminary.core.expression; @safe:

struct Select {
    // TODO: distinct - flag.
    this(string[] cols ...) {
        select = cols.dup;
    }

    private:

    string[] select;
    string[] tables;
    string filter;
}

Select from(Select s, string[] tables ...) pure {
    s.tables = tables;
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
        s.tables ~= name;
    }}
    return s;
}

Select where(Select s, string filter) pure {
    s.filter = filter;
    return s;
}

