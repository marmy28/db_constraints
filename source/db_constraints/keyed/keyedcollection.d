/**
The keyedcollection module contains:
  $(TOC Enforce)
  $(TOC usableForKeyedCollection)
  $(TOC BaseKeyedCollection)
  $(TOC KeyedCollection)

License: $(GPL2)

Authors: Matthew Armbruster

$(B Source:) $(SRC $(SRCFILENAME))

Copyright: 2015
 */
module db_constraints.keyed.keyedcollection;

import std.algorithm : canFind, endsWith, each;
import std.conv : to;
import std.exception : enforceEx;
import std.traits;
import std.typecons : Flag, Yes, No;

import db_constraints.db_exceptions;
import db_constraints.keyed.keyeditem;
import db_constraints.utils.meta;

/**
Tells the keyed collection which constraints to check.
 */
enum Enforce
{
/**
Set $(SRCTAG enforceConstraints) equal to this if you do not want
any constraints to be enforced.
 */
    none = 0,
/**
Enforce the item's check constraint meaning anything with
$(WIKI constraints, NotNull) or $(WIKI constraints, CheckConstraint).

Not using this means an item will not be checked when it is added
to the collection. If you set up the singular class like the examples
though the setter method will still check constraints.
 */
    check = 1,
/**
Enforce the collection does not already contain
the item you are trying to add. Makes sure there would not
be conflicting clustered indicies.
 */
    clusteredUnique = 2,
/**
Enforce all unique constraints are not being violated. If
you have this then you do not need to have clusteredUnique.
 */
    unique = 4,
/**
Enforce the foreign key constraints if there are any.
 */
    foreignKey = 8
}

/**
Makes sure the class is usable for keyed collection. This really just makes sure it
has the necessary members that come with keyeditem.
Returns:
    true if class can be used for keyed collection
 */
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
you include the keyeditem in the $(I T) class.

If $(D T) has foreign keys you must use $(SRCTAG KeyedCollection) instead
since the functions that come with foreign keys need to have the
other class imported.

This also allows you to make a keyed collection in one line.
$(D_CODE alias Candies = BaseKeyedCollection!(Candy);)
Now you can use Candies as a collection.
Params:
    T = the singular class
 */
class BaseKeyedCollection(T)
    if (usableForKeyedCollection!(T))
{
    mixin KeyedCollection!(T);
}


/**
Turns the inheriting class into a keyed collection.
The key is based on the singular class' clustered index.
The requirements (except for dup) are taken care of when
you include the keyeditem in the $(I T) class.

$(D T) should represent a single row in the database. Use
this when $(D T) has foreign keys.
 */
mixin template KeyedCollection(T)
    if (usableForKeyedCollection!(T))
{
    import std.algorithm : canFind, endsWith, each, filter;
    import std.signals;
    import std.traits : isIterable;


/**
The $(D key_type) is alias'd at the type since it looked better than having
$(D typeof(T.key)) everywhere.
 */
    final alias key_type = typeof(T.key);

    private bool _containsChanges;
    private ubyte _enforceConstraints = (Enforce.check | Enforce.unique | Enforce.foreignKey);

    static if (hasForeignKeys!(T))
    {
        mixin(createForeignKeyProperties!(T));
/**
Called when you associate a foreign key or an item changed. This checks
the current items against its foreign keyed class.
 */
        final private void checkForeignKeys()
        {
            this.byValue.each!(
                (T a) =>
                {
                    mixin(createForeignKeyCheckExceptions!(T));
                }());
        }
        /// ditto
        final private void checkForeignKeys(T a)
        {
            mixin(createForeignKeyCheckExceptions!(T));
        }
        mixin(createForeignKeyChanged!(T));
    }
/**
Called when an item is being added or an item changed. This checks
the item's check constraints, unique constraints, and foreign key constraints.
 */
    final private void checkConstraints(T item)
    {
        if (_enforceConstraints & Enforce.check)
        {
            item.checkConstraints();
        }
        if (_enforceConstraints & Enforce.clusteredUnique)
        {
            auto i = (item in this);
            enforceEx!UniqueConstraintException(
                (i is null || (*i) is item),
                "The " ~ key_type.stringof ~ " constraint for class " ~ T.stringof ~
                "  was violated by item " ~ item.toString ~ ".");
        }
        if (_enforceConstraints & Enforce.unique)
        {
            auto constraintName = "";
            enforceEx!UniqueConstraintException(
                !violatesUniqueConstraints(item, constraintName),
                "The " ~ constraintName ~ " constraint for class " ~ T.stringof ~
                "  was violated by item " ~ item.toString ~ ".");
        }
        if (_enforceConstraints & Enforce.foreignKey)
        {
            static if (hasForeignKeys!(T))
            {
                checkForeignKeys(item);
            }
        }
    }
    /// ditto
    final private void checkConstraints(key_type item_key)
    {
        checkConstraints(this[item_key]);
    }
/**
$(D itemChanged) is connected to the signal emitted by the item. This checks
constraints and makes sure the changes are acceptable.
 */
    final private void itemChanged(string propertyName, key_type item_key)
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
/**
The signal used to emit changes that occur in $(D this).
 */
    mixin Signal!(string, key_type) collectionChanged;
/**
Changes $(D this) to not contain changes and also marks all
the items as saved. Should only be used after a save.
 */
    final void markAsSaved() nothrow pure @nogc
    {
        _containsChanges = false;
        this.byValue.each!(a => a.markAsSaved());
    }
/**
Read-only property telling if $(D this) contains changes.
Returns:
    true if $(D this) contains changes.
 */
    final @property bool containsChanges() const nothrow pure @safe @nogc
    {
        return _containsChanges;
    }
/**
Property to enforce the constraints. By default
this is  $(D (Enforce.check | Enforce.unique | Enforce.foreignKey))
but you may set it to 0 if you have a lot of
initial data and already trust that it does not violate any constraints.

Setting this to false means that there are no checks and if there
is a duplicate clustered index, it will be overwritten.
*/
    final @property ubyte enforceConstraints() const nothrow pure @safe @nogc
    {
        return _enforceConstraints;
    }
    /// ditto
    final @property void enforceConstraints(ubyte value) nothrow pure @safe @nogc
    {
        _enforceConstraints = value;
    }

/**
Notifies $(D this) which property changed and sets containsChanges to true.
This also emits a signal with the property name that changed
and the key to it in this collection.
Params:
    propertyName = the property name that changed
    item_key = the items key that changed
 */
    final void notify()(string propertyName, key_type item_key)
    {
        _containsChanges = true;
        collectionChanged.emit(propertyName, item_key);
    }
/**
Removes an item from $(D this) and disconnects the signals. Notifies
that the length of $(D this) has changed by emitting "remove".
 */
    final void remove(key_type item_key, Flag!"notifyChange" notifyChange = Yes.notifyChange)
    {
        if (this.contains(item_key))
        {
            this._items[item_key].disconnect(&itemChanged);
            this._items.remove(item_key);
            if (notifyChange)
            {
                notify("remove", item_key);
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
Adds $(D item) to $(D this) and connects to the signals emitted by $(D item).
Notifies that the length of $(D this) has changed.
Params:
    item(s) = the item(s) you want to add to $(D this)
    notifyChange = whether or not to emit this change. Should only be No if coming from itemChanged

$(THROWS UniqueConstraintException, if $(D this) already contains $(D item) and
enforceConstraints is true.)

$(THROWS CheckConstraintException, if the item is violating any of its
defined check constraints and enforceConstraints is true.)

$(THROWS ForeignKeyException, if the item is violating any of its
foreign key constraints and enforceConstraints is true.)

$(B Precondition:) $(D_CODE assert(item(s) !is null);)
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
            notify("add", item.key);
        }
    }
    /// ditto
    final void add(I)(I items, Flag!"notifyChange" notifyChange = Yes.notifyChange)
        if (isIterable!(I))
    in
    {
        assert(items !is null, "Trying to add a null array");
    }
    body
    {
        foreach(item; items)
        {
            assert(is(typeof(item) == T));
            this.add(item, notifyChange);
        }
    }
/**
This just calls $(SRCTAG add).
 */
    final ref auto opOpAssign(string op : "~")(T item)
    {
        this.add(item);
    }
    /// ditto
    final ref auto opOpAssign(string op : "~", I)(I items)
        if (isIterable!(I))
    {
        this.add(items);
    }

/**
Initializes $(D this). Adds $(D item) to $(D this) and connects to the signals emitted by $(D item).
Params:
    item(s) = the item(s) you want to add to $(D this)

$(THROWS UniqueConstraintException, if $(D this) already contains $(D item) and
enforceConstraints is true.)

$(THROWS CheckConstraintException, if the item is violating any of its
defined check constraints and enforceConstraints is true.)

$(THROWS ForeignKeyException, if the item is violating any of its
foreign key constraints and enforceConstraints is true.)

$(B Precondition:) $(D_CODE assert(item(s) !is null);)
 */
    final this(T item)
    in
    {
        assert(item !is null, "Trying to initialize with a null " ~ T.stringof ~ ".");
    }
    body
    {
        this.add(item, No.notifyChange);
    }
    /// ditto
    final this(I)(I items)
        if (isIterable!(I))
    in
    {
        assert(items !is null, "Trying to initialize with a null iterable.");
    }
    body
    {
        this.add(items, No.notifyChange);
    }


/**
Gets the approriate $(D T). You can either use an item
that equals the item you want back, a key of the item you want
back or parameters that can make the key for the item you want back.
Returns:
    The item in the collection that matches $(D item).

$(THROWS KeyedException, if $(D this) does not contain a matching clustered index.)

$(B Precondition:) $(D_CODE assert(item !is null);)
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
    /// ditto
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
    /// ditto
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
Allows you to use $(D this) in a foreach loop.
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
Checks if $(D item) is in the collection.
Params:
    item = the item you want to see is in the collection
Returns:
    true if $(D item) is in the collection.
 */
    final bool contains(in T item) const nothrow pure @safe @nogc
    {
        return this.contains(item.key);
    }
    /// ditto
    final bool contains(in key_type clIdx) const nothrow pure @safe @nogc
    {
        auto i = (clIdx in this._items);
        return (i !is null);
    }
    /// ditto
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
/**
The $(WEB dlang.org/expression.html#InExpression, InExpression) yields a pointer
to the value if the key is in the associative array, or null if not.
 */
    final inout(T)* opBinaryRight(string op : "in")(in T item) inout nothrow pure @safe @nogc
    {
        return (item.key in this);
    }
    /// ditto
    final inout(T)* opBinaryRight(string op : "in")(in key_type clIdx) inout nothrow pure @safe @nogc
    {
        return (clIdx in this._items);
    }
    /// ditto
    final inout(T)* opBinaryRight(string op : "in", A...)(in A a) inout nothrow pure @safe @nogc
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
is more extensive than $(SRCTAG contains).

$(B Precondition:) $(D_CODE assert(items !is null);)

$(B Postcondition:)
$(D_CODE
if (result)
    assert(constraintName !is null && constraintName != "");
else
    assert(constraintName is null);
)
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
        foreach(uniqueName; GetUniqueConstraintStructNames!(T))
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
    // singular class this holds all of the columns
    class Candy
    {
    private:
        string _name;
        int _ranking;
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

        this(string name, int ranking)
        {
            this._name = name;
            this._ranking = ranking;
            // need to initialize the keyed item
            initializeKeyedItem();
        }
        Candy dup() const
        {
            return new Candy(this._name, this._ranking);
        }
        // the default is to make the primary key into the clustered index
        // which allows you to search based on the primary key
        mixin KeyedItem!();
    }

    // plural class
    // I am using an alias since BaseKeyedCollection
    // takes care of everything I want to do for this example in one line.
    alias Candies = BaseKeyedCollection!(Candy);

    // source: http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/
    // should be Milky not Milkey, this is wrong on purpose
    auto milkyWay = new Candy("Milkey Way", 18);
    auto snickers = new Candy("Snickers", 4);
    auto reesesPBCups = new Candy("Reese's Peanut Butter Cups", 2);

    auto mars = new Candies([milkyWay, snickers]);
    assert(mars.length == 2);
    assert(!mars.containsChanges);

    auto hershey = new Candies(reesesPBCups);
    assert(hershey.length == 1);

    // use the class as an index and confirm it returns the correct value
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
    mars[pk].name = "Milky Way"; // remember pk is primary key for milky way

    // since we changed milky way's name, mars contains changes
    assert(mars.containsChanges);

    // since we had name in pk spelled incorrectly
    // and changed it, the primary key in mars has
    // updated so Milkey Way is no longer in it but
    // Milky Way is.
    assert(!mars.contains("Milkey Way"));
    assert(mars.contains("Milky Way"));

    // looping over mars we make sure the key can be used to get the correct value.
    foreach(name_pk, candy; mars)
    {
        assert(mars[name_pk] == candy);
    }

    // trying to add another candy with the same name will
    // result in a unique constraint violation even if the ranking is different
    auto milkyWay2 = new Candy("Milky Way", 16);
    import std.exception : assertThrown;
    assertThrown!(UniqueConstraintException)(mars ~= milkyWay2);

    // ranking has a check constraint saying ranking always must be greater
    // than 0. setting it to -1 resolves in a CheckConstraintException.
    assertThrown!(CheckConstraintException)(mars["Milky Way"].ranking = -1);
    // Since name is part of the primary key we must mark it with NotNull
    // trying to set this to null will result in a CheckConstraintException.
    assertThrown!(CheckConstraintException)(mars["Milky Way"].name = null);

    // violatesUniqueConstraints will tell you which unique constraint is violated if any
    string violatedConstraint;
    assert(mars.violatesUniqueConstraints(milkyWay2, violatedConstraint));
    assert(violatedConstraint !is null && violatedConstraint == "PrimaryKey");

    // removing milky way from mars
    mars.remove("Milky Way");
    // this means milkyWay2 is no longer a duplicate
    assert(!mars.violatesUniqueConstraints(milkyWay2, violatedConstraint));
    assert(violatedConstraint is null);
}
