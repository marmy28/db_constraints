# db_constraints.keyed.keyedcollection


The keyedcollection module contains:
  + [Enforce](#Enforce)
  + [usableForKeyedCollection](#usableForKeyedCollection)
  + [BaseKeyedCollection](#BaseKeyedCollection)
  + [KeyedCollection](#KeyedCollection)

**License:**
[GPL-2.0](https://github.com/marmy28/db_constraints/blob/master/LICENSE)


**Authors:**
Matthew Armbruster


**Source:** [source/db_constraints/keyed/keyedcollection.d](https://github.com/marmy28/db_constraints/tree/master/source/db_constraints/keyed/keyedcollection.d)



***
<a name="Enforce" href="#Enforce"></a>
```d
enum Enforce: int;

```

Tells the keyed collection which constraints to check.

***
<a name="Enforce.none" href="#Enforce.none"></a>
```d
none
```

Set [KeyedCollection.enforceConstraints](#KeyedCollection.enforceConstraints) equal to this if you do
not want any constraints to be enforced.


***
<a name="Enforce.check" href="#Enforce.check"></a>
```d
check
```

Enforce the item's check constraint meaning anything with
[NotNull](https://github.com/marmy28/db_constraints/wiki/constraints#NotNull) or [CheckConstraint](https://github.com/marmy28/db_constraints/wiki/constraints#CheckConstraint).


Not using this means an item will not be checked when it is added
to the collection. If you set up the singular class like the examples
though the setter method will still check constraints.


***
<a name="Enforce.clusteredUnique" href="#Enforce.clusteredUnique"></a>
```d
clusteredUnique
```

Enforce the collection does not already contain
the item you are trying to add. Makes sure there would not
be conflicting clustered indicies.


***
<a name="Enforce.unique" href="#Enforce.unique"></a>
```d
unique
```

Enforce all unique constraints are not being violated. If
you have this then you do not need to have clusteredUnique.


***
<a name="Enforce.foreignKey" href="#Enforce.foreignKey"></a>
```d
foreignKey
```

Enforce the foreign key constraints if there are any.


***
<a name="Enforce.exclusion" href="#Enforce.exclusion"></a>
```d
exclusion
```

Enforce the exclusion constraints if there are any.

**Version:**
\>= 0.0.7




***
<a name="usableForKeyedCollection" href="#usableForKeyedCollection"></a>
```d
enum auto usableForKeyedCollection(alias T);

```

Makes sure the class is usable for keyed collection. This really just
makes sure it has the necessary members that come with keyeditem.

**Returns:**
true if class can be used for keyed collection


***
<a name="BaseKeyedCollection" href="#BaseKeyedCollection"></a>
```d
class BaseKeyedCollection(T) if (usableForKeyedCollection!T);

```

Turns the inheriting class into a base keyed collection.
The key is based on the singular class' clustered index.
The requirements are taken care of when
you include the keyeditem in the _T_ class.
If you plan on changing the singular class' clustered index,
you must define `dup()` that returns a new instance of your class.


If `T` has foreign keys you must use [KeyedCollection](#KeyedCollection) instead
since the functions that come with foreign keys need to have the
other class imported.


This also allows you to make a keyed collection in one line.

```d
alias Candies = BaseKeyedCollection!(Candy);
```
Now you can use Candies as a collection.

Parameters |
---|
*T*|
&nbsp;&nbsp;&nbsp;&nbsp;the singular class|



***
<a name="KeyedCollection" href="#KeyedCollection"></a>
```d
template KeyedCollection(T) if (usableForKeyedCollection!T)
```

Turns the inheriting class into a keyed collection.
The key is based on the singular class' clustered index.
The requirements (except for dup) are taken care of when
you include the keyeditem in the _T_ class.


`T` should represent a single row in the database. Use
this when `T` has foreign keys.

**Examples:**


```d

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

// Candies is a collection of Candy
static assert(is(Candies.collectionof == Candy));

// source:
// http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/
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
assert(pk.name == milkyWay.name);
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

// looping over mars we make sure the key can be used to get
// the correct value.
foreach(name_pk, candy; mars)
{
    assert(mars[name_pk] == candy);
}

// trying to add another candy with the same name will
// result in a unique constraint violation even if the ranking is different
auto milkyWay2 = new Candy("Milky Way", 16);
assert(milkyWay.name == milkyWay2.name);
assert(milkyWay.ranking != milkyWay2.ranking);
import std.exception : assertThrown;
assertThrown!(UniqueConstraintException)(mars ~= milkyWay2);

// ranking has a check constraint saying ranking always must be greater
// than 0. setting it to -1 resolves in a CheckConstraintException.
assertThrown!(CheckConstraintException)(mars["Milky Way"].ranking = -1);
// Since name is part of the primary key we must mark it with NotNull
// trying to set this to null will result in a CheckConstraintException.
assertThrown!(CheckConstraintException)(mars["Milky Way"].name = null);

// violatesUniqueConstraints will tell you which unique constraint
// is violated if any
string violatedConstraint;
assert(mars.violatesUniqueConstraints(milkyWay2, violatedConstraint));
assert(violatedConstraint !is null && violatedConstraint == "PrimaryKey");

// removing milky way from mars
mars.remove(milkyWay);
// this means milkyWay2 is no longer a duplicate
assert(!mars.violatesUniqueConstraints(milkyWay2, violatedConstraint));
assert(violatedConstraint is null);

```

***
<a name="KeyedCollection.key_type" href="#KeyedCollection.key_type"></a>
```d
alias key_type = typeof(T.key);

```

The `key_type` is alias'd as the type since it looked better than having
`typeof(T.key)` everywhere.


***
<a name="KeyedCollection.collectionof" href="#KeyedCollection.collectionof"></a>
```d
alias collectionof = T;

```

Alias letting you know what this is a collection of.

**Version:**
\>= 0.0.6


***
<a name="KeyedCollection.markAsSaved" href="#KeyedCollection.markAsSaved"></a>
```d
final pure nothrow @nogc void markAsSaved();

```

Changes `this` to not contain changes and also marks all
the items as saved. Should only be used after a save.


***
<a name="KeyedCollection.containsChanges" href="#KeyedCollection.containsChanges"></a>
```d
final const pure nothrow @nogc @property @safe bool containsChanges();

```

Read-only property telling if `this` contains changes.

**Returns:**
true if `this` contains changes.


***
<a name="KeyedCollection.enforceConstraints" href="#KeyedCollection.enforceConstraints"></a>
```d
final pure nothrow @nogc @property @safe void enforceConstraints(ubyte value);

```

Write-only property to enforce the constraints. By default
this is  `(Enforce.check | Enforce.unique | Enforce.foreignKey | Enforce.exclusion)`
but you may set it to 0 if you have a lot of
initial data and already trust that it does not violate any constraints.


Setting this to false means that there are no checks and if there
is a duplicate clustered index, it will be overwritten.


***
<a name="KeyedCollection.notify" href="#KeyedCollection.notify"></a>
```d
final void notify()(string propertyName, key_type item_key);

```

Notifies `this` which property changed and sets containsChanges to true.
This also emits a signal with the property name that changed
and the key to it in this collection.

Parameters |
---|
*string propertyName*|
&nbsp;&nbsp;&nbsp;&nbsp;the property name that changed|
*key_type item_key*|
&nbsp;&nbsp;&nbsp;&nbsp;the items key that changed|



***
<a name="KeyedCollection.remove" href="#KeyedCollection.remove"></a>
```d
final void remove(key_type item_key, Flag!"notifyChange" notifyChange = Yes.notifyChange);

final void remove(T item);

final void remove(A...)(A a);

```

Removes an item from `this` and disconnects the signals. Notifies
that the length of `this` has changed by emitting "remove".


***
<a name="KeyedCollection.add" href="#KeyedCollection.add"></a>
```d
final void add(T item, Flag!"notifyChange" notifyChange = Yes.notifyChange);

final void add(I)(I items, Flag!"notifyChange" notifyChange = Yes.notifyChange) if (isIterable!I);

```

Adds `item` to `this` and connects to the signals emitted by `item`.
Notifies that the length of `this` has changed.


:exclamation: **Throws:**
[UniqueConstraintException](https://github.com/marmy28/db_constraints/wiki/db_exceptions#UniqueConstraintException) if `this` already contains `item` and
enforceConstraints include [Enforce.unique](#Enforce.unique) or
[Enforce.clusteredUnique](#Enforce.clusteredUnique).


:exclamation: **Throws:**
[CheckConstraintException](https://github.com/marmy28/db_constraints/wiki/db_exceptions#CheckConstraintException) if the item is violating any of its
defined check constraints and enforceConstraints include
[Enforce.check](#Enforce.check).


:exclamation: **Throws:**
[ForeignKeyException](https://github.com/marmy28/db_constraints/wiki/db_exceptions#ForeignKeyException) if the item is violating any of its
foreign key constraints and enforceConstraints include
[Enforce.foreignKey](#Enforce.foreignKey).


:exclamation: **Throws:**
[ExclusionConstraintException](https://github.com/marmy28/db_constraints/wiki/db_exceptions#ExclusionConstraintException) if `item` conflicts with any item
in `this` via the ExclusionConstraint and enforceConstraint includes
[Enforce.exclusion](#Enforce.exclusion).


**Precondition:** 
```d
assert(item(s) !is null);
```


Parameters |
---|
*Flag!"notifyChange" notifyChange*|
&nbsp;&nbsp;&nbsp;&nbsp;whether or not to emit this change. Should only be No if coming from itemChanged|



***
<a name="KeyedCollection.opOpAssign" href="#KeyedCollection.opOpAssign"></a>
```d
final ref auto opOpAssign(string op : "~")(T item);

final ref auto opOpAssign(string op : "~", I)(I items) if (isIterable!I);

```

This just calls [KeyedCollection.add](#KeyedCollection.add).


***
<a name="KeyedCollection.this" href="#KeyedCollection.this"></a>
```d
final this(T item);

final this(I)(I items) if (isIterable!I);

final this();

```

Initializes `this`. Adds `item` to `this` and connects to the signals
emitted by `item`.


This just calls [KeyedCollection.add](#KeyedCollection.add).


**Precondition:** 
```d
assert(item(s) !is null);
```


***
<a name="KeyedCollection.opIndex" href="#KeyedCollection.opIndex"></a>
```d
final inout ref inout(T) opIndex(in T item);

final inout ref inout(T) opIndex(in key_type clIdx);

final inout ref inout(T) opIndex(A...)(in A a);

```

Gets the approriate `T`. You can either use an item
that equals the item you want back, a key of the item you want
back or parameters that can make the key for the item you want back.

**Returns:**
The item in the collection that matches `item`.


:exclamation: **Throws:**
[KeyedException](https://github.com/marmy28/db_constraints/wiki/db_exceptions#KeyedException) if `this` does not contain a matching
clustered index.


**Precondition:** 
```d
assert(item !is null);
```


***
<a name="KeyedCollection.opDispatch" href="#KeyedCollection.opDispatch"></a>
```d
auto opDispatch(string name, A...)(A a);

```

Forwards all methods not specified by this abstract class
to the private associative array.


***
<a name="KeyedCollection.opApply" href="#KeyedCollection.opApply"></a>
```d
final int opApply(int delegate(ref T) dg);

final int opApply(int delegate(key_type, ref T) dg);

```

Allows you to use `this` in a foreach loop.


***
<a name="KeyedCollection.length" href="#KeyedCollection.length"></a>
```d
final const pure nothrow @property @safe size_t length();

```

Gets the length of the collection.

**Returns:**
The number of items in the collection.


***
<a name="KeyedCollection.contains" href="#KeyedCollection.contains"></a>
```d
final const pure nothrow @nogc @safe bool contains(in T item);

final const pure nothrow @nogc @safe bool contains(in key_type clIdx);

final const pure nothrow @nogc @safe bool contains(A...)(in A a);

```

Checks if `item` is in the collection.

Parameters |
---|
*T item*|
&nbsp;&nbsp;&nbsp;&nbsp;the item you want to see is in the collection|

**Returns:**
true if `item` is in the collection.


***
<a name="KeyedCollection.opBinaryRight" href="#KeyedCollection.opBinaryRight"></a>
```d
final inout pure nothrow @nogc @safe inout(T)* opBinaryRight(string op : "in")(in T item);

final inout pure nothrow @nogc @safe inout(T)* opBinaryRight(string op : "in")(in key_type clIdx);

final inout pure nothrow @nogc @safe inout(T)* opBinaryRight(string op : "in", A...)(in A a);

```

The [InExpression](http://dlang.org/expression.html#InExpression) yields a pointer
to the value if the key is in the associative array, or null if not.


***
<a name="KeyedCollection.violatesUniqueConstraints" href="#KeyedCollection.violatesUniqueConstraints"></a>
```d
final const pure nothrow bool violatesUniqueConstraints(in T item, out string constraintName);

final const pure nothrow bool violatesUniqueConstraints(in T item);

```

Checks if the item has any conflicting unique constraints. This
is more extensive than [KeyedCollection.contains](#KeyedCollection.contains).


**Precondition:** 
```d
assert(items !is null);
```


**Postcondition:**

```d
if (result)
    assert(constraintName !is null && constraintName != "");
else
    assert(constraintName is null);

```


***
<a name="KeyedCollection.violatesExclusionConstraints" href="#KeyedCollection.violatesExclusionConstraints"></a>
```d
final bool violatesExclusionConstraints(in T item, out string constraintName);

final bool violatesExclusionConstraints(in T item);

```

Checks if the item has any conflicting exclusion constraints.


**Precondition:** 
```d
assert(items !is null);
```


**Postcondition:**

```d
if (result)
    assert(constraintName !is null && constraintName != "");
else
    assert(constraintName is null);

```






Copyright :copyright: 2016 | Page generated by [Ddoc](http://dlang.org/ddoc.html) on Mon Mar  7 19:21:14 2016

