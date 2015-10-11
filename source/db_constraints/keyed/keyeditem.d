/**
Keyed item is used in combination with KeyedCollection to mimic databases
in your classes. This module contains:
  $(TOC KeyedItem)

License: $(GPL2)

Authors: Matthew Armbruster

$(B Source:) $(SRC $(SRCFILENAME))

Copyright: 2015
 */
module db_constraints.keyed.keyeditem;

import std.traits : isInstanceOf;

public import db_constraints.constraints;
import db_constraints.utils.meta : hasMembersWithUDA;

/**
Use this in the singular class which would describe a row in your
database. ClusteredIndexAttribute is the unique constraint associated
with the clustered index.
 */
mixin template KeyedItem(ClusteredIndexAttribute = PrimaryKeyColumn)
    if (isInstanceOf!(UniqueConstraintColumn, ClusteredIndexAttribute))
{
    import std.algorithm : canFind;
    import std.conv : to;
    import std.exception : collectException, enforceEx;
    import std.functional : unaryFun;
    import std.meta : Erase;
    import std.signals;
    import std.string : lastIndexOf;
    import std.traits : isInstanceOf;

    import db_constraints.db_exceptions : CheckConstraintException;
    import db_constraints.utils.meta;

    final private alias T = typeof(this);
    private bool _containsChanges;
    private ClusteredIndex _key;

    static assert(hasMembersWithUDA!(T, ClusteredIndexAttribute),
                  "Must have columns with @UniqueConstraintColumn!\"" ~
                  ClusteredIndexAttribute.name ~ "\" to use this mixin.");

/**
The setter should be in your setter member. This checks your check
constraint and notifies the item if it is different and does not
violate the check constraint.

$(THROWS CheckConstraintException, if your value makes checkConstraints fail.)
 */
    final private void setter(P)(ref P member, P value, string name_ = __FUNCTION__)
    {
        if (value != member)
        {
            P memberValue = member;
            member = value;
            auto ex = collectException!CheckConstraintException(checkConstraints());
            if (ex is null)
            {
                string name = name_[lastIndexOf(name_, '.') + 1 .. $];
                notify(name);
            }
            else
            {
                member = memberValue;
                throw ex;
            }
        }
    }
/**
Initializes the keyed item by running $(SRCTAG setClusteredIndex) and
$(SRCTAG checkConstraints).
This should be in your constructor.

$(THROWS CheckConstraintException, if a member violates their constraint.)
 */
    final private void initializeKeyedItem()
    {
        setClusteredIndex();
        checkConstraints();
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
Changes $(D this) to not contain changes. Should only
be used after a save.
 */
    final void markAsSaved() nothrow pure @safe @nogc
    {
        _containsChanges = false;
    }
/**
The signal used to emit changes that occur in $(D this).
 */
    mixin Signal!(string, typeof(_key)) emitChange;

/**
Notifies $(D this) which property changed. If the property is
part of the clustered index then the clustered index is updated.
This also emits a signal with the property name that changed
along with the clustered index.
Params:
    propertyName = the property name that changed
 */
    final void notify(string propertyName)
    {
        _containsChanges = true;
        emitChange.emit(propertyName, _key);
        if (GetMembersWithUDA!(T, ClusteredIndexAttribute).canFind(propertyName))
        {
            emitChange.emit("key", _key);
            setClusteredIndex();
        }
        foreach(name; Erase!(ClusteredIndexAttribute.name, GetUniqueConstraintStructNames!(T)))
        {
            if (GetMembersWithUDA!(T, UniqueConstraintColumn!name).canFind(propertyName))
            {
                emitChange.emit(name ~ "_key", _key);
            }
        }
        foreach(fk; GetForeignKeys!(T))
        {
            if (fk.columnNames.canFind(propertyName))
            {
                emitChange.emit(fk.name ~ "_key", _key);
            }
        }
    }
/**
Checks if any of the members of $(D T) have values that violate their
check constraint.

$(THROWS CheckConstraintException, if the constraint is violated.)
 */
    final void checkConstraints()
    {
        foreach(member; __traits(derivedMembers, T))
        {
            static if (__traits(compiles, __traits(getMember, T, member)))
            {
                foreach(ov; __traits(getOverloads, T, member))
                {
                    foreach(attr; __traits(getAttributes, ov))
                    {
                        static if (isInstanceOf!(CheckConstraint, attr))
                        {
                            static if (attr.name == "NotNull" || attr.name == "SET")
                            {
                                enum msg = T.stringof ~ "." ~ member ~
                                    " " ~ attr.name ~ " violation.";

                            }
                            else static if (attr.name == "")
                            {
                                enum msg = "chk_" ~ T.stringof ~ "_" ~ member ~
                                    " violation.";
                            }
                            else
                            {
                                enum msg = attr.name ~ " violation.";
                            }
                            enforceEx!(CheckConstraintException)(
                                    attr.check(mixin("this._" ~ member)), msg);
                        }
                    }
                }
            }
        }
    }

/**
Clustered index struct created at compile-time.
This is used to compare classes. The members
are the members of the class marked with the
attribute selected as the Clustered Index.
 */
    final struct ClusteredIndex
    {
        // creates the members of the clustered key with appropriate type.
        mixin(function string()
              {
                  string result = "";
                  foreach(columnName; GetMembersWithUDA!(T, ClusteredIndexAttribute))
                  {
                      result ~= "typeof(" ~ T.stringof ~ "." ~ columnName ~ ") " ~ columnName ~ ";\n";
                  }
                  return result;
              }());
        // adds the generic comparison for structs
        mixin opAAKey!(ClusteredIndex);
    }


/**
The clustered index property for the class.
Returns:
    The clustered index for the class.
 */
    final @property ClusteredIndex key() const nothrow pure @safe @nogc
    {
        return _key;
    }

/**
Sets the clustered index for $(D this).
 */
    final void setClusteredIndex() nothrow pure @safe @nogc
    {
        auto new_key = ClusteredIndex();
        mixin(function string()
              {
                  string result = "";
                  foreach(pkcolumn; GetMembersWithUDA!(T, ClusteredIndexAttribute))
                  {
                      result ~= "new_key." ~ pkcolumn ~ " = this._" ~ pkcolumn ~ ";\n";
                  }
                  return result;
              }());
        this._key = new_key;
    }

    static if (hasForeignKeys!(T))
    {
        mixin(createForeignKeyPropertyConverter!(T));
    }

    mixin(createConstraintStructs!(T, ClusteredIndexAttribute.name));
}

///
unittest
{
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
        typeof(Candy.ranking) ranking;
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
}
