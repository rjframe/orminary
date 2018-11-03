module orminary.core.exception; @safe:

class NoDatabaseConnection : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class NotAModelObject : Exception {
    this(T)(T obj, string file = __FILE__, size_t line = __LINE__) {
        type = obj.stringof;
        super("Object is not a Model type: " ~ obj.stringof);
    }

    string type;
}

// TODO: I don't like the templated exception.
private enum NoExpectedTypeSpecified;
class InvalidType(Given, Expected = NoExpectedTypeSpecified) : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }

    this(string file = __FILE__, size_t line = __LINE__) {
        given = Given.stringof;
        super(given ~ " is not a valid type for this operation", file, line);
    }

    this(Given, Expected)(string file = __FILE__, size_t line = __LINE__) {
        given = Given.stringof;
        expected = Expected.stringof;
        super("Expected type " ~ expected ~ " but received type " ~ given ~ ".",
                file, line);
    }

    string given;
    string expected;
}

class ColumnDoesNotExist : Exception {
    this(string msg, string columnName,
            string file = __FILE__, size_t line = __LINE__) {
        this.columnName = columnName;
        super(msg ~ ": " ~ columnName, file, line);
    }

    string columnName;
}

// I want to avoid Errors.
class RangeViolation : Exception {
    this(size_t idx, size_t len,
            string file = __FILE__, size_t line = __LINE__) {
        import std.conv : text;
        length = len;
        index = idx;
        super("Index out of range: " ~ idx.text ~ ". Length is " ~ len.text);
    }

    size_t length;
    size_t index;
}

class MissingData : Exception {
    this(string msg, string data,
            string file = __FILE__, size_t line = __LINE__) {
        this.data = data;
        super(msg ~ ": " ~ data, file, line);
    }

    this(T)(string msg, T data,
            string file = __FILE__, size_t line = __LINE__) {
        import std.conv : text;
        this.data = data.text;
        super(msg ~ ": " ~ this.data, file, line);
    }

    string data;
}

class InvalidData : Exception {
    this(T)(T data,
            string msg, string file = __FILE__, size_t line = __LINE__) {
        import std.conv : text;
        _data = data.text;
        super(msg ~ ": " ~ _data, file, line);
    }

    string _data;
}
