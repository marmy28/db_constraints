module db_constraints.keyed.keyedcollection;

import std.algorithm : canFind, endsWith, each;
import std.conv : to;
import std.exception : enforceEx;
import std.traits;
import std.typecons : Flag, Yes, No;

import db_constraints.db_exceptions;
import db_constraints.keyed.keyeditem;
import db_constraints.utils.meta : UniqueConstraintStructNames, HasForeignKeys, GetForeignKeyRefTable;

template usableForKeyedCollection(alias T)
{
    enum usableForKeyedCollection = ( is(T == class) &&
        __traits(compiles,
                 (T t)
                 {
                     T i = t.dup();
                     if (i.key == t.key) { }
                     class Example
                     {
                         void itemChanged(string propertyName, typeof(T.key) item_key) { }
                         void add(T item)
                         {
                             item.emitChange.connect(&itemChanged);
                         }
                     }
                     t.checkConstraints();
                     t.markAsSaved();
                     auto j = new Example();
                     j.add(t);
                     string k = t.toString;
                 }));
}

/**
Turns the inheriting class into a base keyed collection.
The key is based on the singular class' clustered index.
The requirements (except for dup) are taken care of when
you include the keyeditem in the *T* class.
Params:
    T = the singular class.
 */
class BaseKeyedCollection(T)
    if (usableForKeyedCollection!(T))
{
    mixin KeyedCollection!(T);
}

mixin template KeyedCollection(T)
    if (usableForKeyedCollection!(T))
{
    import std.signals;

/**
The key type is alias'd at the type since it looked better than having
typeof(T.key) everywhere.
 */
    final alias key_type = typeof(T.key);

    private bool _containsChanges;
    private bool _enforceConstraints = true;

    static if (HasForeignKeys!(T))
    {
        mixin(function string()
              {
                  import std.uni : toLower;
                  string result = "";
                  foreach(member; GetForeignKeyRefTable!(T))
                  {
                      static assert(member != member.toLower, "The class " ~ member ~ " should start with a capital letter to use Foreign Keys or else there will be name collisions.");
                      result ~= "private " ~ member ~ " *_" ~ member.toLower ~ ";\n";
                      result ~= "private " ~ member ~ ".key_type _changed" ~ member ~ "Row;\n";

                      result ~= "final @property void " ~ member.toLower ~ "(ref " ~ member ~ " " ~ member.toLower ~ "_)\n";
                      result ~= "{\n";
                      result ~= "    this._" ~ member.toLower ~ " = &" ~ member.toLower ~ "_;\n";
                      result ~= "    this._" ~ member.toLower ~ ".collectionChanged.connect(&foreignKeyChanged);\n";
                      result ~= "    checkForeignKeys();\n";
                      result ~= "}\n";
                  }
                  return result;
              }());
    }
/**
Called when an item is being added or an item changed.
 */
    final private void checkConstraints(T item)
    {
        if (_enforceConstraints)
        {
            auto constraintName = "";
            item.checkConstraints();
            enforceEx!UniqueConstraintException(
                !violatesUniqueConstraints(item, constraintName),
                "The " ~ constraintName ~ " constraint for class " ~ T.stringof ~
                "  was violated by item " ~ item.toString ~ ".");
        }
    }
    /// ditto
    final private void checkConstraints(key_type item_key)
    {
        checkConstraints(this[item_key]);
    }
/**
itemChanged is connected to the signal emitted by the item. This checks
constraints and makes sure the changes are acceptable.
 */
    protected void itemChanged(string propertyName, key_type item_key)
    {
        key_type emit_key = item_key;
        if (propertyName == "key")
        {
            T item = this._items[item_key].dup();
            this.remove(item_key, No.notifyChange);
            this.add(item, No.notifyChange);
            emit_key = item.key;
        }
        else if (propertyName.endsWith("_key"))
        {
            checkConstraints(item_key);
        }
        notify(propertyName, emit_key);
    }
    T[key_type] _items;

    mixin Signal!(string, key_type) collectionChanged;
/**
Changes `this` to not contain changes. Should only
be used after a save.
 */
    final void markAsSaved() nothrow pure @nogc
    {
        _containsChanges = false;
        this.byValue.each!(a => a.markAsSaved());
    }
/**
Read-only property telling if `this` contains changes.
Returns:
    true if `this` contains changes.
 */
    final @property bool containsChanges() const nothrow pure @safe @nogc
    {
        return _containsChanges;
    }
/**
Getter and setter to enforce the constraints. By default
this is true but you may set it to false if you have a lot of
initial data and already trust that is unique and accurate.

Setting this to false means that there are no checks and if there
is a duplicate clustered index, it will be overwritten.
*/
    final @property bool enforceConstraints() const nothrow pure @safe @nogc
    {
        return _enforceConstraints;
    }
    /// ditto
    final @property void enforceConstraints(bool value) nothrow pure @safe @nogc
    {
        _enforceConstraints = value;
    }

/**
Notifies `this` which property changed.
This also emits a signal with the property name that changed.
Params:
    propertyName = the property name that changed.
    item_key = the items key that changed.
 */
    final void notify()(string propertyName, key_type item_key)
    {
        _containsChanges = true;
        collectionChanged.emit(propertyName, item_key);
    }
    /// ditto
    final void notify(string propertyName)(key_type item_key)
    {
        _containsChanges = true;
        collectionChanged.emit(propertyName, item_key);
    }
/**
Removes an item from `this` and disconnects the signals. Notifies
that the length of `this` has changed.
 */
    final void remove(key_type item_key, Flag!"notifyChange" notifyChange = Yes.notifyChange)
    {
        if (this.contains(item_key))
        {
            this._items[item_key].disconnect(&itemChanged);
            this._items.remove(item_key);
            if (notifyChange)
            {
                notify!("remove")(item_key);
            }
        }
    }
    /// ditto
    final void remove(T item)
    in
    {
        assert(item !is null, "Trying to remove a null item.");
    }
    body
    {
        this.remove(item.key);
    }
    /// ditto
    final void remove(A...)(A a)
    in
    {
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
    notifyChange = whether or not to emit this change. Should only be No if coming from itemChanged
Throws:
    UniqueConstraintException if `this` already contains `item` and
    enforceConstraints is true.
Throws:
    CheckConstraintException if the item is violating any of its
    defined check constraints and enforceConstraints is true.
 */
    final void add(T item, Flag!"notifyChange" notifyChange = Yes.notifyChange)
    in
    {
        assert(item !is null, "Trying to add a null item.");
    }
    body
    {
        this.checkConstraints(item);
        item.emitChange.connect(&itemChanged);
        this._items[item.key] = item;
        if (notifyChange)
        {
            notify!("add")(item.key);
        }
    }
    /// ditto
    final this(T item)
    {
        this.add(item, No.notifyChange);
    }
    /// ditto
    final ref auto opOpAssign(string op)(T item)
        if (op == "~")
    {
        this.add(item);
    }
/**
Does the same as `add(T item)` but for an array.
 */
    final void add(T[] items)
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
    final this(T[] items)
    {
        foreach(item; items)
        {
            this.add(item, No.notifyChange);
        }
    }
    /// ditto
    final ref auto opOpAssign(string op)(T[] items)
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
Throws:
    KeyedException if `this` does not contain a matching clustered index.
 */
    final ref inout(T) opIndex(in T item) inout
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
Throws:
    KeyedException if `this` does not contain a matching clustered index.
 */
    final ref inout(T) opIndex(in key_type clIdx) inout
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
                fields ~= clIdx.tupleof[i].stringof ~ " = " ~ j.to!string() ~ "\n";
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
Throws:
    KeyedException if `this` does not contain a matching clustered index.
 */
    final ref inout(T) opIndex(A...)(in A a) inout
    in
    {
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
    final int opApply(int delegate(ref T) dg)
    {
        int result = 0;
        foreach(T i; this.values)
        {
            result = dg(i);
            if (result)
                break;
        }
        return result;
    }
    /// ditto
    final int opApply(int delegate(key_type, ref T) dg)
    {
        int result = 0;
        foreach(T i; this.values)
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
    final size_t length() const @property @safe nothrow pure
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
    final bool contains(in T item) const nothrow pure @safe @nogc
    {
        return this.contains(item.key);
    }
    /// ditto
    inout(T)* opBinaryRight(string op)(in T item) inout nothrow pure @safe @nogc
        if (op == "in")
    {
        return (item.key in this);
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
    final bool contains(in key_type clIdx) const nothrow pure @safe @nogc
    {
        auto i = (clIdx in this._items);
        return (i !is null);
    }
    /// ditto
    final inout(T)* opBinaryRight(string op)(in key_type clIdx) inout nothrow pure @safe @nogc
        if (op == "in")
    {
        return (clIdx in this._items);
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
    final bool contains(A...)(in A a) const nothrow pure @safe @nogc
    in
    {
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
    final inout(T)* opBinaryRight(string op, A...)(in A a) inout nothrow pure @safe @nogc
        if (op == "in")
    in
    {
        static assert(A.length == key_type.tupleof.length, T.stringof ~
                      " has a clustered index with " ~ key_type.tupleof.length.to!string ~
                      " member(s). You included " ~ A.length.to!string ~
                      " members when using 'in'.");
    }
    body
    {
        auto clIdx = key_type(a);
        return (clIdx in this);
    }
/**
Checks if the item has any conflicting unique constraints. This
is more extensive than `contains`.
 */
    final bool violatesUniqueConstraints(in T item, out string constraintName) const nothrow pure
    in
    {
        assert(item !is null, "Cannot check if a null item is duplicated.");
    }
    out (result)
    {
        if (result)
            assert(constraintName !is null && constraintName != "");
        else
            assert(constraintName is null);
    }
    body
    {
        bool result = false;
        foreach(uniqueName; UniqueConstraintStructNames!(T))
        {
            if (this._items.byValue.canFind!("a !is b && " ~
                                      "a." ~ uniqueName ~ "_key == " ~
                                      "b." ~ uniqueName ~ "_key")(item))
            {
                result = true;
                if (constraintName is null)
                {
                    constraintName = uniqueName;
                }
                else
                {
                    constraintName ~= ", " ~ uniqueName;
                }
            }
        }
        return result;
    }
    // ditto
    final bool violatesUniqueConstraints(in T item) const nothrow pure
    {
        string constraintName;
        return this.violatesUniqueConstraints(item, constraintName);
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
        @PrimaryKeyColumn @NotNull
        @property string name() const nothrow pure @safe @nogc
        {
            return _name;
        }
        @property void name(string value)
        {
            setter(_name, value);
        }
        @property int ranking() const nothrow pure @safe @nogc
        {
            return _ranking;
        }
        // making sure that ranking will always be above 0
        @CheckConstraint!(a => a > 0, "chk_Candys_ranking")
        @property void ranking(int value)
        {
            setter(_ranking, value);
        }
        @property int annualSales() const nothrow pure @safe @nogc
        {
            return _annualSales;
        }
        @property void annualSales(int value)
        {
            setter(_annualSales, value);
        }
        @property string brand() const nothrow pure @safe @nogc
        {
            return _brand;
        }
        @property void brand(string value)
        {
            setter(_brand, value);
        }

        this(string name, immutable(int) ranking, immutable(int) annualSales, string brand)
        {
            this._name = name;
            this._ranking = ranking;
            this._annualSales = annualSales;
            this._brand = brand;
            // need to initialize the keyed item
            initializeKeyedItem();
        }
        Candy dup() const
        {
            return new Candy(this._name, this._ranking, this._annualSales, this._brand);
        }
        // the default is to make the primary key into the clustered index
        // which allows you to search based on the primary key
        mixin KeyedItem!();
    }

    // plural class
    // I am using an alias since BaseKeyedCollection
    // takes care of everything I want to do for this example.
    alias Candies = BaseKeyedCollection!(Candy);

    // source: http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/
    auto milkyWay = new Candy("Milkey Way", 18, 129_000_000, "Mars");
    // should be Milky not Milkey, this is wrong on purpose
    auto snickers = new Candy("Snickers", 4, 441_100_000, "Mars");
    auto reesesPBCups = new Candy("Reese's Peanut Butter Cups", 2, 516_500_000, "Hershey");

    auto mars = new Candies([milkyWay, snickers]);
    assert(mars.length == 2);
    assert(!mars.containsChanges);

    // use the class as an index
    assert(mars[milkyWay] is milkyWay);
    // use the primary key as an index
    auto pk = Candy.PrimaryKey("Milkey Way");
    assert(mars[pk] is milkyWay);
    // use the contents of the primary key as an index
    assert(mars["Milkey Way"] is milkyWay);

    // milky way is in mars
    assert(mars.contains(pk));
    // reesesPBCups is not in mars
    assert(!mars.contains(reesesPBCups));

    // now we change the name to be correct
    mars[pk].name = "Milky Way";
    assert(mars.containsChanges);

    // since we had name in pk spelled incorrectly
    // and changed it, the primary key in mars has
    // updated so Milkey Way is no longer in it but
    // Milky Way is.
    assert(!mars.contains("Milkey Way"));
    assert(mars.contains("Milky Way"));

    foreach(name_pk, candy; mars)
    {
        assert(mars[name_pk] == candy);
    }

    // trying to add another candy with the same name will
    // result in a unique constraint violation
    auto milkyWay2 = new Candy("Milky Way", 18, 0, null);
    import std.exception : assertThrown;
    assertThrown!(UniqueConstraintException)(mars ~= milkyWay2);

    // ranking has a check constraint saying ranking always must be greater
    // than 0. setting it to -1 resolves in a CheckConstraintException.
    assertThrown!(CheckConstraintException)(mars["Milky Way"].ranking = -1);
    // Since name is part of the primary key we must mark it with NotNull
    // trying to set this to null will result in a CheckConstraintException.
    assertThrown!(CheckConstraintException)(mars["Milky Way"].name = null);

    // violatesUniqueConstraints will tell you which constraint is violated if any
    string violatedConstraint;
    assert(mars.violatesUniqueConstraints(milkyWay2, violatedConstraint));
    assert(violatedConstraint !is null && violatedConstraint == "PrimaryKey");

    // removing milky way from mars
    mars.remove("Milky Way");
    // this means milkyWay2 is no longer a duplicate
    assert(!mars.violatesUniqueConstraints(milkyWay2, violatedConstraint));
    assert(violatedConstraint is null);
}
