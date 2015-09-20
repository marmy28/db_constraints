module db_extensions.keyed.keyedcollection;

import std.signals;
import std.traits;
import std.exception : enforceEx;

import db_extensions.keyed.keyeditem;
import db_extensions.extra.db_exceptions;


/**
Turns the inheriting class into a base keyed collection.
The key is based on the singular class' clustered index.
T must have a dup property and a key property.
The clustered index and key are created when you include the keyeditem in your class.
Params:
    T = the singular class.
 */
abstract class BaseKeyedCollection(T)
    if (hasMember!(T, "dup") &&
        hasMember!(T, "key") &&
        hasMember!(T, "emitChange") &&
        hasMember!(T, "checkConstraints")
        )
{
public:
/**
The key type is alias'd at the type since it looked better than having
typeof(T.key) everywhere.
 */
    alias key_type = typeof(T.key);
private:
    bool _containsChanges;
    bool _enforceConstraints = true;
    final void checkConstraints(key_type item_key)
    {
        checkConstraints(this[item_key]);
    }
    final void checkConstraints(T item)
    {
        if (_enforceConstraints)
        {
            auto constraintName = "";
            item.checkConstraints();
            enforceEx!UniqueConstraintException(
                !violatesUniqueConstraints(item, constraintName),
                "The " ~ constraintName ~ " constraint was violated by " ~ item.toString ~ ".");
        }
    }
protected:
    void itemChanged(string propertyName, key_type item_key)
    {
        import std.algorithm : endsWith;
        if (propertyName == "key")
        {
            T item = this._items[item_key].dup();
            this.remove(item_key);
            this.add(item);
        }
        else if (propertyName.endsWith("_key"))
        {
            checkConstraints(item_key);
        }
        notify(propertyName);
    }
    T[key_type] _items;
public:
    mixin Signal!(string);
final:
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
    bool containsChanges() const @property nothrow pure @safe @nogc
    {
        return _containsChanges;
    }
/**
Getter and setter to enforce the unique constraints. By default
this is true but you may set it to false if you have a lot of
initial data and already trust that is unique.

Setting this to false means that there are no checks and if there
is a duplicate clustered index, it will be overwritten.
*/
    bool enforceConstraints() const @property nothrow pure @safe @nogc
    {
        return _enforceConstraints;
    }
    /// ditto
    void enforceConstraints(bool value) @property nothrow pure @safe @nogc
    {
        _enforceConstraints = value;
    }

/**
Notifies `this` which property changed.
This also emits a signal with the property name that changed.
Params:
    propertyName = the property name that changed.
 */
    void notify(string propertyName)
    {
        _containsChanges = true;
        emit(propertyName);
    }
/**
Removes an item from `this` and disconnects the signals. Notifies
that the length of `this` has changed.
 */
    void remove(key_type item_key)
    {
        if (this.contains(item_key))
        {
            this._items[item_key].disconnect(&itemChanged);
            this._items.remove(item_key);
            notify("length");
        }
    }
    /// ditto
    void remove(T item)
    in
    {
        assert(item !is null, "Trying to remove a null item.");
    }
    body
    {
        this.remove(item.key);
    }
    /// ditto
    void remove(A...)(A a)
    in
    {
        import std.conv;
        static assert(A.length == key_type.tupleof.length, T.stringof ~
                      " has a clustered index with " ~ key_type.tupleof.length.to!string ~
                      " member(s). You included " ~ A.length.to!string ~
                      " members when using remove.");
    }
    body
    {
        auto clIdx = key_type(a);
        return this.remove(clIdx);
    }
/**
Adds `item` to `this` and connects to the signals emitted by `item`.
Notifies that the length of `this` has changed.
Params:
    item = the item you want to add to `this`.
Throws:
    UniqueConstraintException if `this` already contains `item` and
    enforceConstraints is true.
 */
    void add(T item)
    in
    {
        assert(item !is null, "Trying to add a null item.");
    }
    body
    {
        this.checkConstraints(item);
        item.emitChange.connect(&itemChanged);
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
    UniqueConstraintException if `this` already contains `item`.
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
    ref T opIndex(T item)
    in
    {
        assert(item !is null, "Trying to lookup with a null.");
    }
    body
    {
        return this[item.key];
    }
/**
Gets the approriate `T` that has clustered index `clIdx`.
Params:
    clIdx = the clustered index of the item you want back.
Returns:
    The item in the collection that has clustered index `clIdx`.
 */
    ref T opIndex(key_type clIdx)
    {
        if (this.contains(clIdx))
        {
            return this._items[clIdx];
        }
        else
        {
            auto fields = "\nAn item with clustered index of:\n";
            foreach(i, j; clIdx.tupleof)
            {
                fields ~= clIdx.tupleof[i].stringof ~ " = " ~ std.conv.to!string(j) ~ "\n";
            }
            fields ~= "does not exist in " ~ typeof(this).stringof;
            throw new KeyedException(fields);
        }
    }
/**
Gets the approriate `T` that has clustered index `a`.
Params:
    a = the fields of the clustered index of the item you want back.
Returns:
    The item in the collection that has the clustered index with fields `a`.
 */
    ref T opIndex(A...)(A a)
    in
    {
        import std.conv;
        static assert(A.length == key_type.tupleof.length, T.stringof ~
                      " has a clustered index with " ~ key_type.tupleof.length.to!string ~
                      " member(s). You included " ~ A.length.to!string ~
                      " members when using the index.");
    }
    body
    {
        auto clIdx = key_type(a);
        return this[clIdx];
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
Checks if `clIdx` is in the collection.
Params:
    clIdx = the clustered index of the item you want
    to see is in the collection.
Returns:
    true if there is a clustered index in the collection that
    matches `clIdx`.
 */
    bool contains(key_type clIdx) nothrow pure @safe @nogc
    {
        auto i = (clIdx in this._items);
        return (i !is null);
    }
    /// ditto
    bool opBinaryRight(string op)(key_type clIdx) nothrow pure @safe @nogc
        if (op == "in")
    {
        return this.contains(clIdx);
    }
/**
Checks if `a` makes a clustered index that is in the collection.
Params:
    a = the fields of the clustered index of the item you want
    to see is in the collection.
Returns:
    true if there is a clustered index in the collection that
    matches `a`.
 */
    bool contains(A...)(A a) nothrow pure @safe @nogc
    in
    {
        import std.conv;
        static assert(A.length == key_type.tupleof.length, T.stringof ~
                      " has a clustered index with " ~ key_type.tupleof.length.to!string ~
                      " member(s). You included " ~ A.length.to!string ~
                      " members when using contains.");
    }
    body
    {
        auto clIdx = key_type(a);
        return this.contains(clIdx);
    }
    /// ditto
    bool opBinaryRight(string op, A...)(A a) nothrow pure @safe @nogc
        if (op == "in")
    {
        return this.contains(a);
    }
/**
Checks if the item has any conflicting unique constraints. This
is more extensive than `contains`.
 */
    bool violatesUniqueConstraints(T item, out string constraintName)
    in
    {
        assert(item !is null, "Cannot check if a null item is duplicated.");
    }
    out (result)
    {
        if (result)
            assert(constraintName !is null && constraintName != "");
        else
            assert(constraintName == "");
    }
    body
    {
        import std.algorithm : canFind, endsWith;

        bool result = false;
        constraintName = "";
        foreach(uniqueName; T.UniqueConstraintStructNames!(T))
        {
            if (this.byValue.canFind!("a !is b && " ~
                                      "a." ~ uniqueName ~ "_key == " ~
                                      "b." ~ uniqueName ~ "_key")(item))
            {
                result = true;
                constraintName ~= uniqueName ~ ", ";
            }
        }

        if (constraintName.endsWith(", "))
        {
            constraintName = constraintName[0..$-2];
        }
        return result;
    }
    // ditto
    bool violatesUniqueConstraints(T item)
    {
        auto constraintName = "";
        auto result = this.violatesUniqueConstraints(item, constraintName);
        return result;
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
        // marking name as part of the primary key
        string name() const @property @PrimaryKeyColumn nothrow pure @safe @nogc
        {
            return _name;
        }
        void name(string value) @property
        {
            setter(_name, value);
        }
        int ranking() const @property nothrow pure @safe @nogc
        {
            return _ranking;
        }
        void ranking(int value) @property
        {
            setter(_ranking, value);
        }
        int annualSales() const @property nothrow pure @safe @nogc
        {
            return _annualSales;
        }
        void annualSales(int value) @property
        {
            setter(_annualSales, value);
        }
        string brand() const @property nothrow pure @safe @nogc
        {
            return _brand;
        }
        // this can only be Mars or Hershey
        @CheckConstraint!((a) => a == "Mars" || a == "Hershey")
        void brand(string value) @property
        {
            setter(_brand, value);
        }

        this(string name, immutable(int) ranking, immutable(int) annualSales, string brand)
        {
            this._name = name;
            this._ranking = ranking;
            this._annualSales = annualSales;
            this._brand = brand;
            initializeKeyedItem();
        }
        Candy dup() const
        {
            return new Candy(this._name, this._ranking, this._annualSales, this._brand);
        }
        // the default is to make the primary key into the clustered index
        // which allows you to search based on the primary key
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
    // use the contents of the primary key as an index
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
    assert("Milkey Way" !in mars);
    assert(mars.contains("Milky Way"));

    foreach(name_pk, candy; mars)
    {
        assert(mars[name_pk] == candy);
    }

    // trying to add another candy with the same name will
    // result in a unique constraint violation
    auto milkyWay2 = new Candy("Milky Way", 0, 0, "Mars");
    import std.exception : assertThrown;
    assertThrown!(CheckConstraintException)(mars["Milky Way"].brand = "Cars");

    assertThrown!(UniqueConstraintException)(mars ~= milkyWay2);

    auto violatedConstraint = "";
    assert(mars.violatesUniqueConstraints(milkyWay2, violatedConstraint));
    assert(violatedConstraint == "PrimaryKey");

    // removing milky way from mars
    mars.remove("Milky Way");
    // this means milkyWay2 is no longer a duplicate
    assert(!mars.violatesUniqueConstraints(milkyWay2, violatedConstraint));
    assert(violatedConstraint == "");


}
