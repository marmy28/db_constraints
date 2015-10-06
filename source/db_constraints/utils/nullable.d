/**
 * This is basically std.typecons.Nullable with extra features.
 *
 * Copyright: Copyright the respective authors, 2008-
 * License:   Boost License 1.0
 * Authors:   Andrei Alexandrescu,
 *            Bartosz Milewski,
 *            Don Clugston,
 *            Shin Fujishiro,
 *            Kenji Hara,
 *            Matthew Armbruster
 */
module db_constraints.utils.nullable;

import std.traits : isBuiltinType;

template isNullable(T, I)
{
    enum isNullable = __traits(compiles,
                               (I i)
                               {
                                   Nullable!T test = i;
                               });
}

/**
Defines a value paired with a distinctive "null" state that denotes
the absence of a value. If default constructed, a $(D
Nullable!T) object starts in the null state. Assigning it renders it
non-null. Calling $(D nullify) can nullify it again.
Practically $(D Nullable!T) stores a $(D T) and a $(D bool).
 */
struct Nullable(T)
{
    private T _value;
    private bool _isNull = true;

/**
Constructor initializing $(D this) with $(D value).
Params:
    value = The value to initialize this `Nullable` with.
 */
    this(inout T value) inout
    {
        _value = value;
        _isNull = false;
    }
    this(N : typeof(null))(N n) inout nothrow pure @safe @nogc
    {
    }

    template toString()
    {
        import std.format : FormatSpec, formatValue;
        // Needs to be a template because of DMD @@BUG@@ 13737.
        void toString()(scope void delegate(const(char)[]) sink, FormatSpec!char fmt)
        {
            if (isNull)
            {
                sink.formatValue("Nullable.null", fmt);
            }
            else
            {
                sink.formatValue(_value, fmt);
            }
        }

        // Issue 14940
        void toString()(scope void delegate(const(char)[]) @safe sink, FormatSpec!char fmt)
        {
            if (isNull)
            {
                sink.formatValue("Nullable.null", fmt);
            }
            else
            {
                sink.formatValue(_value, fmt);
            }
        }
    }

/**
Check if `this` is in the null state.
Returns:
    true $(B iff) `this` is in the null state, otherwise false.
 */
    @property bool isNull() const @safe pure nothrow @nogc
    {
        return _isNull;
    }

///
unittest
{
    Nullable!int ni;
    assert(ni.isNull);

    ni = 0;
    assert(!ni.isNull);
}

// Issue 14940
@safe unittest
{
    import std.array : appender;
    import std.format : formattedWrite;

    auto app = appender!string();
    Nullable!int a = 1;
    formattedWrite(app, "%s", a);
    assert(app.data == "1");
}






    static if (!is(T == immutable(T)) && !is(T == const(T)))
    {
/**
Assigns $(D value) to the internally-held state. If the assignment
succeeds, $(D this) becomes non-null.
Params:
    value = A value of type `T` to assign to this `Nullable`.
 */
        void opAssign()(T value)
        {
            _value = value;
            _isNull = false;
        }
/**
Forces $(D this) to the null state.
 */
        void nullify()() @safe nothrow pure @nogc
        {
            .destroy(_value);
            _isNull = true;
        }
        /// ditto
        void opAssign(N : typeof(null))(N n) @safe nothrow pure @nogc
            if (!__traits(compiles, T.init == null))
        {
            this.nullify();
        }
    }

///
unittest
{
    Nullable!int ni = 0;
    assert(!ni.isNull);

    ni.nullify();
    assert(ni.isNull);
}
/**
    If this `Nullable` wraps a type that already has a null value
    (such as a pointer), then assigning the null value to this
    `Nullable` is no different than assigning any other value of
    type `T`, and the resulting code will look very strange. It
    is strongly recommended that this be avoided by instead using
    the version of `Nullable` that takes an additional `nullValue`
    template argument.
 */
unittest
{
    //Passes
    Nullable!(int*) npi;
    assert(npi.isNull);

    //Passes?!
    npi = null;
    assert(!npi.isNull);
}
    static if (__traits(compiles, (T a, T b) { return a == b; }) && !is(T == class))
    {
        bool opEquals(N : typeof(null))(N n) const nothrow pure @safe @nogc
        {
            return this.isNull;
        }
        bool opEquals(inout T rhs) const nothrow pure
        {
            bool result = false;
            if (!this.isNull)
            {
                result = (this._value == rhs);
            }
            return result;
        }
        bool opEquals(Nullable!T rhs) const
        {
            bool result = false;
            if (!rhs.isNull)
            {
                result = this.opEquals(rhs.get);
            }
            else if (!this.isNull)
            {
                result = false;
            }
            else
            {
                result = true;
            }
            return result;
        }
    }
    static if (__traits(compiles, (T a, T b) { return a > b; }) && !is(T == class))
    {
        int opCmp(N : typeof(null))(N n) const nothrow pure @safe @nogc
        {
            return (this.isNull ? 0 : 1);
        }
        int opCmp(inout T rhs) const nothrow pure
        {
            int result = -1;
            if (!this.isNull)
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
            return result;
        }
        int opCmp(Nullable!T rhs) const nothrow pure
        {
            int result = 0;
            if (!rhs.isNull)
            {
                result = this.opCmp(rhs.get);
            }
            else if (!this.isNull)
            {
                result = 1;
            }
            return result;
        }
    }


/**
Gets the value. $(D this) must not be in the null state.
This function is also called for the implicit conversion to $(D T).
Returns:
    The value held internally by this `Nullable`.
 */
    @property ref inout(T) get() inout @safe pure nothrow
    in
    {
        enum message = "Called `get' on null Nullable!" ~ T.stringof ~ ".";
        assert(!isNull, message);
    }
    body
    {
        return _value;
    }
/**
Gets the value or the default value passed in.
Returns:
    The value held internally by this `Nullable` or the extra value passed in.
 */
    auto ref inout(T) getValueOr(lazy inout T defVal) inout
    {
        return (this.isNull ? defVal : this.get);
    }

///
unittest
{
    import std.exception: assertThrown, assertNotThrown;

    Nullable!int ni;
    //`get` is implicitly called. Will throw
    //an AssertError in non-release mode
    assertThrown!Throwable(ni += 1);

    ni = 0;
    assertNotThrown!Throwable(ni += 1);
}

/**
Implicitly converts to $(D T).
$(D this) must not be in the null state.
 */
    alias get this;
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

    Nullable!CustomerRecord getByName(string name)
    {
        //A bunch of hairy stuff

        return Nullable!CustomerRecord.init;
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
    Nullable!int i;
    assert(i.isNull);
    i = 3;
    assert(!i.isNull);
    i = null;
    assert(i.isNull);
}

unittest
{
    Nullable!int i = 3;
    assert(i.get == 3);
    assert(i.getValueOr(4) == 3);
    i = null;
    assert(i.isNull && i.getValueOr(4) == 4);
}

unittest
{
    Nullable!int i = null;
    assert(i == null);
    i = 3;
    assert(i == 3);
    Nullable!int j;
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
    Nullable!int i;
    Nullable!int j;
    assert(i == j);
    i = 5;
    j = 6;
    assert(i != j);
}

unittest
{
    Nullable!int i;
    Nullable!int j = 3;
    //assert(i < j);
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
    Nullable!Example i;
    assert(i.isNull);
    assert(i == null);
    i = Example("Tom", 9);
    assert(!i.isNull);
    assert(i != null);
    auto j = Example("Tom", 9);
    assert(i == j);
    i = null;
    assert(i != j);
}

unittest
{
    import std.exception : assertThrown;

    Nullable!int a;
    assert(a.isNull);
    assertThrown!Throwable(a.get);
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
    auto k = Nullable!int(74);
    assert(k == 74);
    k.nullify();
    assert(k.isNull);
}
unittest
{
    static int f(in Nullable!int x) {
        return x.isNull ? 42 : x.get;
    }
    Nullable!int a;
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
    Nullable!S s;
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
    // Ensure Nullable can be used in pure/nothrow/@safe environment.
    function() @safe pure nothrow
    {
        Nullable!int n;
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
    // Ensure Nullable can be used when the value is not pure/nothrow/@safe
    static struct S
    {
        int x;
        this(this) @system {}
    }

    Nullable!S s;
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
    alias N = Nullable!int;

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
        auto a1 = Nullable!(immutable int)();
        auto a2 = Nullable!(immutable int)(1);
        auto i = a2.get;
    }
    //Check immutable nullable is constructable
    {
        auto a1 = immutable (Nullable!int)();
        auto a2 = immutable (Nullable!int)(1);
        auto i = a2.get;
    }
}
unittest
{
    alias NInt   = Nullable!int;

    //Construct tests
    {
        //from other Nullable null
        NInt a1;
        NInt b1 = a1;
        assert(b1.isNull);

        //from other Nullable non-null
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
        //from other Nullable null
        NInt a1;
        NInt b1;
        b1 = a1;
        assert(b1.isNull);

        //from other Nullable non-null
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
    import std.meta : AliasSeq;
    //Check nullable is nicelly embedable in a struct
    static struct S1
    {
        Nullable!int ni;
    }
    static struct S2 //inspired from 9404
    {
        Nullable!int ni;
        this(S2 other)
        {
            ni = other.ni;
        }
        void opAssign(S2 other)
        {
            ni = other.ni;
        }
    }
    foreach (S; AliasSeq!(S1, S2))
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
    auto na = Nullable!JSONValue(value);

    struct S1 { int val; }
    struct S2 { int* val; }
    struct S3 { immutable int* val; }

    {
        auto sm = S1(1);
        immutable si = immutable S1(1);
        static assert( __traits(compiles, { auto x1 =           Nullable!S1(sm); }));
        static assert( __traits(compiles, { auto x2 = immutable Nullable!S1(sm); }));
        static assert( __traits(compiles, { auto x3 =           Nullable!S1(si); }));
        static assert( __traits(compiles, { auto x4 = immutable Nullable!S1(si); }));
    }

    auto nm = 10;
    immutable ni = 10;

    {
        auto sm = S2(&nm);
        immutable si = immutable S2(&ni);
        static assert( __traits(compiles, { auto x =           Nullable!S2(sm); }));
        static assert(!__traits(compiles, { auto x = immutable Nullable!S2(sm); }));
        static assert(!__traits(compiles, { auto x =           Nullable!S2(si); }));
        static assert( __traits(compiles, { auto x = immutable Nullable!S2(si); }));
    }

    {
        auto sm = S3(&ni);
        immutable si = immutable S3(&ni);
        static assert( __traits(compiles, { auto x =           Nullable!S3(sm); }));
        static assert( __traits(compiles, { auto x = immutable Nullable!S3(sm); }));
        static assert( __traits(compiles, { auto x =           Nullable!S3(si); }));
        static assert( __traits(compiles, { auto x = immutable Nullable!S3(si); }));
    }
}
unittest
{
    // Bugzila 10357
    import std.datetime;
    Nullable!SysTime time = SysTime(0);
}
unittest
{
    import std.conv: to;
    import std.array;

    // Bugzilla 10915
    Appender!string buffer;

    Nullable!int ni;
    assert(ni.to!string() == "Nullable.null");

    struct Test { string s; }
    alias NullableTest = Nullable!Test;

    NullableTest nt = Test("test");
    assert(nt.to!string() == `Test("test")`);

    NullableTest ntn = Test("null");
    assert(ntn.to!string() == `Test("null")`);

    class TestToString
    {
        double d;

        this (double d)
        {
            this.d = d;
        }

        override string toString()
        {
            return d.to!string();
        }
    }
    Nullable!TestToString ntts = new TestToString(2.5);
    assert(ntts.to!string() == "2.5");
}
