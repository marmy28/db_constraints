module db_extensions.keyed.keyedcollection;

import std.signals;
import std.traits;

import db_extensions.keyed.keyeditem;
import db_extensions.extra.db_exceptions;

/**
Turns the inheriting class into a base keyed collection.
The key is based on the singular class' Primary Key.
Params:
    $(D T) must have a dup property, a primary key, and
    a key property. The primary key and key are created
    when you include the keyeditem in your class.
 */
abstract class BaseKeyedCollection(T)
    if (hasMember!(T, "dup") &&
        hasMember!(T, "key")
        )
{
private:
    alias key_type = typeof(T.key);
    bool _containsChanges;

    void keyChanged(key_type oldPK, key_type newPK)
    {
        T item = this._items[oldPK].dup();
        this._items.remove(oldPK);
        this._items[newPK] = item;
    }
    T[key_type] _items;
public:
/**
Changes `this` to not contain changes. Should only
be used after a save.
 */
    void markAsSaved() nothrow pure @safe @nogc
    {
        _containsChanges = false;
    }
/**
Read-only property telling if `this` contains changes.
Returns:
    true if `this` contains changes.
 */
    bool containsChanges() @property nothrow pure @safe @nogc
    {
        return _containsChanges;
    }
    mixin Signal!(string);
/**
Notifies `this` which property changed. If the property is
part of the primary key then the primary key is updated.
This also emits a signal with the property name that changed.
Params:
    propertyName = the property name that changed.
 */
    void notify(string propertyName)
    {
        _containsChanges = true;
        emit(propertyName);
        debug(signal) writeln("You changed ", propertyName);
    }
/**
Adds `item` to `this` and connects to the signals emitted by `item`.
Notifies that the length of `this` has changed.
Params:
    item = the item you want to add to `this`.
Throws:
    PrimaryKeyException if `this` already contains `item`.
 */
    void add(T item)
    in
    {
        assert(item !is null, "Trying to add a null item.");
    }
    body
    {
        if (this.contains(item))
        {
            throw new PrimaryKeyException(item.toString ~ " was added again.");
        }
        item.simple.connect(&notify);
        item.primary_key.connect(&keyChanged);
        this._items[item.key] = item;
        notify("length");
    }
    /// ditto
    this(T item)
    {
        this.add(item);
        this._containsChanges = false;
    }
    /// ditto
    ref auto opOpAssign(string op)(T item)
        if (op == "~")
    {
        this.add(item);
    }
/**
Adds `items` to `this` and connects to the signals emitted by each item.
Notifies that the length of `this` has changed.
Params:
    items = the items you want to add to `this`.
Throws:
    PrimaryKeyException if `this` already contains `item`.
 */
    void add(T[] items)
    in
    {
        assert(items !is null, "Trying to add a null array");
    }
    body
    {
        foreach(item; items)
        {
            this.add(item);
        }
    }
    /// ditto
    this(T[] items)
    {
        this.add(items);
        this._containsChanges = false;
    }
    /// ditto
    ref auto opOpAssign(string op)(T[] items)
        if (op == "~")
    {
        this.add(items);
    }
/**
Gets the approriate `T` that equals `item`.
Params:
    item = the item you want back from the collection.
Returns:
    The item in the collection that matches `item`.
 */
    ref T opIndex(T item) nothrow pure @safe
    {
        return this._items[item.key];
    }
/**
Gets the approriate `T` that has primary key `pk`.
Params:
    pk = the primary key of the item you want back.
Returns:
    The item in the collection that has primary key `pk`.
 */
    ref T opIndex(key_type pk)
    {
        return this._items[pk];
    }
/**
Gets the approriate `T` that has primary key `a`.
Params:
    a = the fields of the primary key of the item you want back.
Returns:
    The item in the collection that has the primary key with fields `a`.
 */
    ref T opIndex(A...)(A a)
    in
    {
        import std.conv;
        static assert(A.length == key_type.tupleof.length, T.stringof ~
                      " has a primary key with " ~ key_type.tupleof.length.to!string ~
                      " member(s). You included " ~ A.length.to!string ~
                      " members when using the index.");
    }
    body
    {
        auto pk = key_type(a);
        return this._items[pk];
    }
/**
Forwards all methods not specified by this abstract class
to the private associative array.
 */
    auto opDispatch(string name, A...)(A a)
    {
        debug(dispatch) pragma(msg, "opDispatch", name);
        return mixin("this._items." ~ name ~ "(a)");
    }
/**
Allows you to use `this` in a foreach loop.
 */
    int opApply(int delegate(ref T) dg)
    {
        int result = 0;
        foreach(T i; this._items.values)
        {
            result = dg(i);
            if (result)
                break;
        }
        return result;
    }
    /// ditto
    int opApply(int delegate(key_type, ref T) dg)
    {
        int result = 0;
        foreach(T i; this._items.values)
        {
            result = dg(i.key, i);
            if (result)
                break;
        }
        return result;
    }
/**
Gets the length of the collection.
Returns:
    The number of items in the collection.
 */
    size_t length() @property @safe nothrow pure
    {
        return this._items.length;
    }
/**
Checks if `item` is in the collection.
Params:
    item = the item you want to see is in the collection.
Returns:
    true if `item` is in the collection.
 */
    bool contains(T item) nothrow pure @safe @nogc
    {
        return this.contains(item.key);
    }
    /// ditto
    bool opBinaryRight(string op)(T item) nothrow pure @safe @nogc
        if (op == "in")
    {
        return this.contains(item);
    }
/**
Checks if `pk` is in the collection.
Params:
    pk = the primary key of the item you want
    to see is in the collection.
Returns:
    true if there is a primary key in the collection that
    matches `pk`.
 */
    bool contains(key_type pk) nothrow pure @safe @nogc
    {
        auto i = (pk in this._items);
        return (i !is null);
    }
    /// ditto
    bool opBinaryRight(string op)(key_type pk) nothrow pure @safe @nogc
        if (op == "in")
    {
        return this.contains(pk);
    }
/**
Checks if `a` makes a primary key that is in the collection.
Params:
    a = the fields of the primary key of the item you want
    to see is in the collection.
Returns:
    true if there is a primary key in the collection that
    matches `a`.
 */
    bool contains(A...)(A a) nothrow pure @safe @nogc
    in
    {
        import std.conv;
        static assert(A.length == key_type.tupleof.length, T.stringof ~
                      " has a primary key with " ~ key_type.tupleof.length.to!string ~
                      " member(s). You included " ~ A.length.to!string ~
                      " members when using contains.");
    }
    body
    {
        auto pk = key_type(a);
        return this.contains(pk);
    }
    /// ditto
    bool opBinaryRight(string op, A...)(A a) nothrow pure @safe @nogc
        if (op == "in")
    {
        return this.contains(a);
    }
}

///
unittest
{
    // singular class
    class Candy
    {
    private:
        string _name;
        int _ranking;
        int _annualSales;
        string _brand;
    public:
        string name() const @property @PrimaryKeyColumn() nothrow pure @safe @nogc
        {
            return _name;
        }
        void name(string value) @property
        {
            if (value != _name)
            {
                _name = value;
                notify("name");
            }
        }
        int ranking() const @property nothrow pure @safe @nogc
        {
            return _ranking;
        }
        void ranking(int value) @property
        {
            if (value != _ranking)
            {
                _ranking = value;
                notify("ranking");
            }
        }
        int annualSales() const @property nothrow pure @safe @nogc
        {
            return _annualSales;
        }
        void annualSales(int value) @property
        {
            if (value != _annualSales)
            {
                _annualSales = value;
                notify("annualSales");
            }
        }
        string brand() const @property nothrow pure @safe @nogc
        {
            return _brand;
        }
        void brand(string value) @property
        {
            if (value != _brand)
            {
                _brand = value;
                notify("brand");
            }
        }

        this(string name, immutable(int) ranking, immutable(int) annualSales, string brand)
        {
            this._name = name;
            this._ranking = ranking;
            this._annualSales = annualSales;
            this._brand = brand;
            // do not forget to set the primary key
            setPrimaryKey();
        }
        Candy dup() const
        {
            return new Candy(this._name, this._ranking, this._annualSales, this._brand);
        }
        mixin KeyedItem!(typeof(this));
    }

    // plural class
    class Candies : BaseKeyedCollection!(Candy)
    {
    public:
        this(Candy[] items)
        {
            super(items);
        }
        this(Candy item)
        {
            super(item);
        }
    }

    // source: http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/
    auto milkyWay = new Candy("Milkey Way", 18, 129_000_000, "Mars");
    // should be Milky not Milkey, this is wrong on purpose
    auto snickers = new Candy("Snickers", 4, 441_100_000, "Mars");
    auto reesesPBCups = new Candy("Reese's Peanut Butter Cups", 2, 516_500_000, "Hershey");

    auto mars = new Candies([milkyWay, snickers]);
    assert(mars.length == 2);
    assert(!mars.containsChanges);

    // use the class as an index
    assert(mars[milkyWay] == milkyWay);
    // use the primary key as an index
    auto pk = Candy.PrimaryKey("Milkey Way");
    assert(mars[pk] == milkyWay);
    assert(mars["Milkey Way"] == milkyWay);

    // milky way is in mars
    assert(pk in mars);
    // reesesPBCups is not in mars
    assert(!mars.contains(reesesPBCups));

    // now we change the name to be correct
    mars[pk].name = "Milky Way";
    assert(mars.containsChanges);

    // since we had name in pk spelled incorrectly
    // and changed it, the primary key in mars has
    // updated so Milkey Way is no longer in it but
    // Milky Way is.
    assert(pk !in mars);
    pk.name = "Milky Way";
    assert(mars.contains(pk));
    assert(mars.contains("Milky Way"));

    foreach(name_pk, candy; mars)
    {
        assert(mars[name_pk] == candy);
    }

    // trying to add another candy with the same name will
    // result in a primary key violation
    auto milkyWay2 = new Candy("Milky Way", 0, 0, "");
    import std.exception : assertThrown;
    assertThrown!(Throwable)(mars ~= milkyWay2);
}
