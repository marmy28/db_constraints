# db_constraints.keyed.keyeditem


Keyed item is used in combination with KeyedCollection to mimic databases
in your classes. This module contains:
  + [KeyedItem](#KeyedItem)

**License:**
[GPL-2.0](https://github.com/marmy28/db_constraints/blob/master/LICENSE)


**Authors:**
Matthew Armbruster


**Source:** [source/db_constraints/keyed/keyeditem.d](https://github.com/marmy28/db_constraints/tree/master/source/db_constraints/keyed/keyeditem.d)



***
<a name="KeyedItem" href="#KeyedItem"></a>
```d
template KeyedItem(ClusteredIndexAttribute = PrimaryKeyColumn) if (isInstanceOf!(UniqueConstraintColumn, ClusteredIndexAttribute))
```

Use this in the singular class which would describe a row in your
database. ClusteredIndexAttribute is the unique constraint associated
with the clustered index.

**Examples:**


```d

class Candy
{
private:
    string _name;
    int _ranking;
public:
    // name is the primary key
    @PrimaryKeyColumn @NotNull
    @property string name() const nothrow pure @safe @nogc
    {
        return _name;
    }
    @property void name(string value)
    {
        setter(_name, value);
    }
    // ranking must be unique among all the other records
    @UniqueConstraintColumn!("uc_Candy_ranking")
    @property int ranking() const nothrow pure @safe @nogc
    {
        return _ranking;
    }
    // making sure that ranking will always be above 0
    @CheckConstraint!(a => a > 0, "chk_Candy_ranking")
    @property void ranking(int value)
    {
        setter(_ranking, value);
    }
    this(string name, int ranking)
    {
        this._name = name;
        this._ranking = ranking;
        initializeKeyedItem();
    }

    // The primary key is now the clustered index as it is by default
    mixin KeyedItem!(PrimaryKeyColumn);
}

// below is what is created when you include the mixin KeyedItem
// ClusteredIndex is alias'd as PrimaryKey since we said the
// primary key is our clustered index above.
// this also creates a uc_Candy_ranking struct and key since
// we labeled ranking with @UniqueConstraintColumn!("uc_Candy_ranking")
enum candyStructs =
`public:
final alias PrimaryKey = ClusteredIndex;
final alias PrimaryKey_key = key;
final struct uc_Candy_ranking
{
    typeof(Candy._ranking) ranking;
    mixin opAAKey!(uc_Candy_ranking);
}
final @property uc_Candy_ranking uc_Candy_ranking_key() const nothrow pure @safe @nogc
{
    auto _uc_Candy_ranking_key = uc_Candy_ranking();
    _uc_Candy_ranking_key.ranking = this._ranking;
    return _uc_Candy_ranking_key;
}
`;
import db_constraints.utils.meta : createConstraintStructs;
static assert(createConstraintStructs!(Candy, "PrimaryKey") == candyStructs);
assert(createConstraintStructs!(Candy, "PrimaryKey") == candyStructs);


// source: http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/10.htm
auto i = new Candy("Opal Fruit", 17);

// i does not contain changes
assert(!i.containsChanges);

auto pk = Candy.PrimaryKey("Opal Fruit");
// the key property is the clustered index
// since we said the primary key is the clustered index
// i.key and pk are equal
assert(i.key == pk);
// PrimaryKey_key is an alias for key
assert(i.key == i.PrimaryKey_key);
// the primary key struct has member name since that was marked
// with @PrimaryKeyColumn
assert(i.key.name == pk.name);
assert(i.name == pk.name);

auto j = new Candy("Opal Fruit", 16);
// since name is the primary key i and j are equal because
// the names are equal
// even though the ranking is different
assert(i.key == j.key);
assert(i.ranking != j.ranking);

// in 1967 Opal Fruits came to America and changed its name
i.name = "Starburst";
// i now contains changes since we changed the name
assert(i.containsChanges);
i.markAsSaved();
// once we mark it as saved it no longer contains changes
assert(!i.containsChanges);

// by changing the name it also changes the primary key
// so now i.key should not equal the pk we defined above
// or j.key
assert(i.key != pk);
assert(i.key != j.key);

import std.exception : assertThrown;
import db_constraints.db_exceptions : CheckConstraintException;
// we expect setting the ranking to 0 will result in an exception
// since we labeled that column with
// @CheckConstraint!(a => a > 0, "chk_Candy_ranking")
assertThrown!CheckConstraintException(i.ranking = 0);

```

***
<a name="KeyedItem.containsChanges" href="#KeyedItem.containsChanges"></a>
```d
final const pure nothrow @nogc @property @safe bool containsChanges();

```

Read-only property telling if `this` contains changes.

**Returns:**
true if `this` contains changes.


***
<a name="KeyedItem.markAsSaved" href="#KeyedItem.markAsSaved"></a>
```d
final pure nothrow @nogc @safe void markAsSaved();

```

Changes `this` to not contain changes. Should only
be used after a save.


***
<a name="KeyedItem.notify" href="#KeyedItem.notify"></a>
```d
final void notify(string propertyName);

```

Notifies `this` which property changed. If the property is
part of the clustered index then the clustered index is updated.
This also emits a signal with the property name that changed
along with the clustered index.

Parameters |
---|
*string propertyName*|
&nbsp;&nbsp;&nbsp;&nbsp;the property name that changed|



***
<a name="KeyedItem.checkConstraints" href="#KeyedItem.checkConstraints"></a>
```d
final void checkConstraints();

```

Checks if any of the members of `T` have values that violate their
check constraint.


:exclamation: **Throws:**
[CheckConstraintException](https://github.com/marmy28/db_constraints/wiki/db_exceptions#CheckConstraintException) if the constraint is violated.


***
<a name="KeyedItem.ClusteredIndex" href="#KeyedItem.ClusteredIndex"></a>
```d
struct ClusteredIndex;

```

Clustered index struct created at compile-time.
This is used to compare classes. The members
are the members of the class marked with the
attribute selected as the Clustered Index.


***
<a name="KeyedItem.key" href="#KeyedItem.key"></a>
```d
final const pure nothrow @nogc @property @safe ClusteredIndex key();

```

The clustered index property for the class.

**Returns:**
The clustered index for the class.


***
<a name="KeyedItem.setClusteredIndex" href="#KeyedItem.setClusteredIndex"></a>
```d
final pure nothrow @nogc @safe void setClusteredIndex();

```

Sets the clustered index for `this`.






Copyright :copyright: 2016 | Page generated by [Ddoc](http://dlang.org/ddoc.html) on Mon Mar  7 19:21:14 2016

