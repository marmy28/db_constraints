module db_constraints.utils.dbnullable;

/**
Defines a value paired with a distinctive "null" state that denotes
the absence of a value. If default constructed, a $(D
DBNullable!T) object starts in the null state. Assigning it renders it
non-null. Assigning null can nullify it again.
Practically $(D DBNullable!T) stores a $(D T) and a $(D bool).
`T` cannot have an initial value of null for example strings or classes.
 */
struct DBNullable(T)
    if (!__traits(compiles, T.init == null))
{
private:
    T _value;
    bool _hasValue;
public:
/**
Constructor initializing $(D this) with $(D value).
Params:
    value = The value to initialize this `DBNullable` with.
 */
    this(inout T value) inout
    {
        this._value = value;
        this._hasValue = true;
    }

/**
Constructor initializing $(D this) to be null.
*/
    this(A : typeof(null))(A) inout nothrow pure @safe @nogc
    {
    }

    template toString()
    {
        import std.format : FormatSpec, formatValue;
        // Needs to be a template because of DMD @@BUG@@ 13737.
        void toString()(scope void delegate(const(char)[]) sink, FormatSpec!char fmt)
        {
            if (this.hasValue)
            {
                sink.formatValue(_value, fmt);
            }
            else
            {
                sink.formatValue("DBNullable.null", fmt);
            }
        }
    }

/**
Check if `this` has a value.
Returns:
    true $(B iff) `this` has a value, otherwise false.
*/
    bool hasValue() const @property nothrow pure @safe @nogc
    {
        return this._hasValue;
    }
///
unittest
{
    DBNullable!int ni;
    assert(!ni.hasValue);

    ni = 0;
    assert(ni.hasValue);
}
/**
Check if `this` is in the null state.
Returns:
    true $(B iff) `this` is in the null state, otherwise false.
*/
    bool isNull() const @property nothrow pure @safe @nogc
    {
        return !this.hasValue;
    }
///
unittest
{
    DBNullable!int ni;
    assert(ni.isNull);

    ni = 0;
    assert(!ni.isNull);
}

    static if (!is(T == immutable(T)) && !is(T == const(T)))
    {
/**
Assigns $(D rhs) to the internally-held state. If the assignment
succeeds, $(D this) becomes non-null.
Params:
    rhs = A value of type `T` to assign to this `DBNullable`.
 */
        void opAssign(T rhs) //nothrow pure @safe @nogc
        {
            this._value = rhs;
            this._hasValue = true;
        }
/**
Forces $(D this) to the null state.
 */
        void opAssign(RHS : typeof(null))(RHS rhs) nothrow pure @safe @nogc
        {
            this._value = T.init;
            this._hasValue = false;
        }

///
unittest
{
    DBNullable!int ni = 0;
    assert(ni.hasValue);
    ni = null;
    assert(!ni.hasValue);
}
/**
Forces $(D this) to the null state.
Deprecated:
    Assign null instead.
 */
        void nullify() nothrow pure @safe
        {
            this._value = T.init;
            _hasValue = false;
        }
    }
///
unittest
{
    DBNullable!int ni = 0;
    assert(!ni.isNull);

    ni.nullify();
    assert(ni.isNull);
}

    // opEquals section
    bool opEquals(RHS : typeof(null))(inout RHS) const nothrow pure @safe @nogc
    {
        return (this.hasValue ? false : true);
    }
    bool opEquals(DBNullable!T rhs) const
    {
        bool result = false;
        if (rhs.hasValue)
        {
            result = this.opEquals(rhs.get);
        }
        else if (this.hasValue)
        {
            result = false;
        }
        else
        {
            result = true;
        }
        return result;
    }
    bool opEquals(inout T rhs) const nothrow pure
    {
        bool result = false;
        if (this.hasValue)
        {
            result = (this._value == rhs);
        }
        return result;
    }

/**
Only allow the comparison if `T` is not a struct or if `T` is a struct
and has defined opCmp
*/
    static if (!is(T == struct) || (is(T == struct) && __traits(compiles,this._value.opCmp(T.init) )))
    {
        int opCmp(RHS : typeof(null))(inout RHS) const nothrow pure @safe @nogc
        {
            return (this.hasValue ? 1 : 0);
        }
        int opCmp(DBNullable!T rhs) const nothrow pure
        {
            int result = 0;
            if (rhs.hasValue)
            {
                result = this.opCmp(rhs.get);
            }
            else if (this.hasValue)
            {
                result = 1;
            }
            return result;
        }
        int opCmp(inout T rhs) const nothrow pure
        {
            int result = -1;
            if (this.hasValue)
            {
                static if (__traits(compiles, this._value.opCmp(rhs)))
                {
                    result = (this._value.opCmp(rhs));
                }
                else
                {
                    if (this._value < rhs)
                    {
                        result = -1;
                    }
                    else if (this._value > rhs)
                    {
                        result = 1;
                    }
                    else
                    {
                        result = 0;
                    }
                }
            }
            return result;
        }
    }
/**
Gets the value.
This function is also called for the implicit conversion to $(D T).
Returns:
    The value held internally by this `DBNullable` or null.
 */
    deprecated("Use get instead")
    ref inout(T) value() inout @property nothrow pure @safe @nogc
    {
        return *(this.hasValue ? &this._value : null);
    }
/**
Gets the value or the extra value passed in.
Returns:
    The value held internally by this `DBNullable` or the extra value passed in.
 */
    auto ref getValueOr(lazy inout T extra_value) pure @safe
    {
        return (this.hasValue ? this._value : extra_value);
    }
    deprecated("Use getValueOr")
    auto ref valueOr(lazy inout T extra_value) pure @safe
    {
        return (this.hasValue ? this._value : extra_value);
    }

/**
Gets the value. $(D this) must not be in the null state.
Returns:
    The value held internally by this `DBNullable`.
Deprecated:
    Use value instead.
 */
    ref inout(T) get() inout @property nothrow pure @safe @nogc
    {
        enum message = "Called `get' on null DBNullable!" ~ T.stringof ~ ".";
        assert(this.hasValue, message);
        return _value;
    }

/**
Implicitly converts to $(D T).
 */
    alias get this;
}


unittest
{
    DBNullable!int i;
    assert(i.isNull && !i.hasValue);
    i = 3;
    assert(i.hasValue && !i.isNull);
    i = null;
    assert(i.isNull && !i.hasValue);
}

unittest
{
    DBNullable!int i = 3;
    assert(i.get == 3);
    assert(i.getValueOr(4) == 3);
    i = null;
    assert(i.isNull && i.getValueOr(4) == 4);
}

unittest
{
    DBNullable!int i = null;
    assert(i == null);
    i = 3;
    assert(i == 3);
    DBNullable!int j;
    assert(i != j);
    assert(i == j.getValueOr(3));
    int returns3(ref int count)
    {
        count += 1;
        return 3;
    }
    int lazycalls = 0;
    assert(i == j.getValueOr(returns3(lazycalls)));
    assert(lazycalls == 1);
    i = 2;
    j = 2;
    assert(i == j.getValueOr(returns3(lazycalls)));
    assert(lazycalls == 1);
}

unittest
{
    DBNullable!int i;
    DBNullable!int j;
    assert(i == j);
    i = 5;
    j = 6;
    assert(i != j);
}

unittest
{
    DBNullable!int i;
    DBNullable!int j = 3;
    assert(i < j);
    i = 5;
    j = 6;
    assert(i != j);
}

unittest
{
    import std.string;
    struct Example
    {
        string name;
        int number;
        bool opEquals(inout(Example) ex) const pure nothrow @nogc @safe
        {
            return (this.name == ex.name && this.number == ex.number);
        }
    }
    DBNullable!Example i;
    assert(!i.hasValue);
    assert(i == null);
    i = Example("Tom", 9);
    assert(i.hasValue);
    assert(i != null);
    auto j = Example("Tom", 9);
    assert(i == j);
    i = null;
    assert(i != j);
}


///
unittest
{
    struct CustomerRecord
    {
        string name;
        string address;
        int customerNum;
    }

    DBNullable!CustomerRecord getByName(string name)
    {
        //A bunch of hairy stuff

        return DBNullable!CustomerRecord.init;
    }

    auto queryResult = getByName("Doe, John");
    if (!queryResult.isNull)
    {
        //Process Mr. Doe's customer record
        auto address = queryResult.address;
        auto customerNum = queryResult.customerNum;

        //Do some things with this customer's info
    }
    else
    {
        //Add the customer to the database
    }
}

unittest
{
    import std.exception : assertThrown;

    DBNullable!int a;
    assert(a.isNull);
    a = 5;
    assert(!a.isNull);
    assert(a == 5);
    assert(a != 3);
    assert(a.get != 3);
    a.nullify();
    assert(a.isNull);
    a = 3;
    assert(a == 3);
    a *= 6;
    assert(a == 18);
    a = a;
    assert(a == 18);
    a.nullify();
    assertThrown!Throwable(a += 2);
}
unittest
{
    auto k = DBNullable!int(74);
    assert(k == 74);
    k.nullify();
    assert(k.isNull);
}
unittest
{
    static int f(in DBNullable!int x) {
        return x.isNull ? 42 : x.get;
    }
    DBNullable!int a;
    assert(f(a) == 42);
    a = 8;
    assert(f(a) == 8);
    a.nullify();
    assert(f(a) == 42);
}
unittest
{
    import std.exception : assertThrown;

    static struct S { int x; }
    DBNullable!S s;
    assert(s.isNull);
    s = S(6);
    assert(s == S(6));
    assert(s != S(0));
    assert(s.get != S(0));
    s.x = 9190;
    assert(s.x == 9190);
    s.nullify();
    assertThrown!Throwable(s.x = 9441);
}
unittest
{
    // Ensure DBNullable can be used in pure/nothrow/@safe environment.
    function() @safe pure nothrow
    {
        DBNullable!int n;
        assert(n.isNull);
        n = 4;
        assert(!n.isNull);
        assert(n == 4);
        n.nullify();
        assert(n.isNull);
    }();
}
unittest
{
    // Ensure DBNullable can be used when the value is not pure/nothrow/@safe
    static struct S
    {
        int x;
        this(this) @system {}
    }

    DBNullable!S s;
    assert(s.isNull);
    s = S(5);
    assert(!s.isNull);
    assert(s.x == 5);
    s.nullify();
    assert(s.isNull);
}
unittest
{
    // Bugzilla 9404
    alias N = DBNullable!int;

    void foo(N a)
    {
        N b;
        b = a; // `N b = a;` works fine
    }
    N n;
    foo(n);
}
unittest
{
    //Check nullable immutable is constructable
    {
        auto a1 = DBNullable!(immutable int)();
        auto a2 = DBNullable!(immutable int)(1);
        auto i = a2.get;
    }
    //Check immutable nullable is constructable
    {
        auto a1 = immutable (DBNullable!int)();
        auto a2 = immutable (DBNullable!int)(1);
        auto i = a2.get;
    }
}
unittest
{
    alias NInt   = DBNullable!int;

    //Construct tests
    {
        //from other DBNullable null
        NInt a1;
        NInt b1 = a1;
        assert(b1.isNull);

        //from other DBNullable non-null
        NInt a2 = NInt(1);
        NInt b2 = a2;
        assert(b2 == 1);

        //Construct from similar nullable
        auto a3 = immutable(NInt)();
        NInt b3 = a3;
        assert(b3.isNull);
    }

    //Assign tests
    {
        //from other DBNullable null
        NInt a1;
        NInt b1;
        b1 = a1;
        assert(b1.isNull);

        //from other DBNullable non-null
        NInt a2 = NInt(1);
        NInt b2;
        b2 = a2;
        assert(b2 == 1);

        //Construct from similar nullable
        auto a3 = immutable(NInt)();
        NInt b3 = a3;
        b3 = a3;
        assert(b3.isNull);
    }
}
unittest
{
    import std.typetuple : TypeTuple;
    //Check nullable is nicelly embedable in a struct
    static struct S1
    {
        DBNullable!int ni;
    }
    static struct S2 //inspired from 9404
    {
        DBNullable!int ni;
        this(S2 other)
        {
            ni = other.ni;
        }
        void opAssign(S2 other)
        {
            ni = other.ni;
        }
    }
    foreach (S; TypeTuple!(S1, S2))
    {
        S a;
        S b = a;
        S c;
        c = a;
    }
}
unittest
{
    // Bugzilla 10268
    import std.json;
    JSONValue value = null;
    auto na = DBNullable!JSONValue(value);

    struct S1 { int val; }
    struct S2 { int* val; }
    struct S3 { immutable int* val; }

    {
        auto sm = S1(1);
        immutable si = immutable S1(1);
        static assert( __traits(compiles, { auto x1 =           DBNullable!S1(sm); }));
        static assert( __traits(compiles, { auto x2 = immutable DBNullable!S1(sm); }));
        static assert( __traits(compiles, { auto x3 =           DBNullable!S1(si); }));
        static assert( __traits(compiles, { auto x4 = immutable DBNullable!S1(si); }));
    }

    auto nm = 10;
    immutable ni = 10;

    {
        auto sm = S2(&nm);
        immutable si = immutable S2(&ni);
        static assert( __traits(compiles, { auto x =           DBNullable!S2(sm); }));
        static assert(!__traits(compiles, { auto x = immutable DBNullable!S2(sm); }));
        static assert(!__traits(compiles, { auto x =           DBNullable!S2(si); }));
        static assert( __traits(compiles, { auto x = immutable DBNullable!S2(si); }));
    }

    // {
    //     auto sm = S3(&ni);
    //     immutable si = immutable S3(&ni);
    //     static assert( __traits(compiles, { auto x =           DBNullable!S3(sm); }));
    //     static assert( __traits(compiles, { auto x = immutable DBNullable!S3(sm); }));
    //     static assert( __traits(compiles, { auto x =           DBNullable!S3(si); }));
    //     static assert( __traits(compiles, { auto x = immutable DBNullable!S3(si); }));
    // }
}
unittest
{
    // Bugzila 10357
    import std.datetime;
    DBNullable!SysTime time = SysTime(0);
}
unittest
{
    import std.conv: to;
    import std.array;

    // Bugzilla 10915
    Appender!string buffer;

    DBNullable!int ni;
    assert(ni.to!string() == "DBNullable.null");

    struct Test { string s; }
    alias NullableTest = DBNullable!Test;

    NullableTest nt = Test("test");
    assert(nt.to!string() == `Test("test")`);

    NullableTest ntn = Test("null");
    assert(ntn.to!string() == `Test("null")`);

    struct TestToString
    {
        double d;

        this (double d)
        {
            this.d = d;
        }

        string toString()
        {
            return d.to!string();
        }
    }
    DBNullable!TestToString ntts = TestToString(2.5);
    assert(ntts.to!string() == "2.5");
}

unittest
{
    bool inputNullable(DBNullable!int a)
    {
        return a.isNull;
    }
    assert(inputNullable(cast(DBNullable!int)null));
    assert(!inputNullable(cast(DBNullable!int)3));
}
