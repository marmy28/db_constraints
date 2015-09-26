module db_constraints.keyed.keyeditem;

public import db_constraints.constraints;

/**
Use this in the singular class which would describe a row in your
database.
Params:
    T = the type of the class this is mixed into.
    ClusteredIndexAttribute = the attribute associated with the clustered index.
 */
mixin template KeyedItem(T, ClusteredIndexAttribute = PrimaryKeyColumn)
    if (is(T == class))
{
    import std.algorithm : canFind;
    import std.array;
    import std.conv : to;
    import std.exception : collectException, enforceEx;
    import std.functional : unaryFun;
    import std.meta : Erase, NoDuplicates;
    import std.signals;
    import std.string : lastIndexOf;
    import std.traits : isInstanceOf, hasUDA;
    import std.typetuple : TypeTuple;

    import db_constraints.db_exceptions : CheckConstraintException;
    import db_constraints.utils.generickey : generic_compare;
private:
    bool _containsChanges;
    ClusteredIndex _key;

/**
The setter should be in your setter member. This checks your check constraint.
Throws:
    CheckConstraintException if your value makes checkConstraints fail.
 */
    template setter(string name_ = __FUNCTION__)
        if (name_ !is null)
    {
        void setter(P)(ref P member, P value)
        {
            enum name = name_[lastIndexOf(name_, '.') + 1 .. $];
            if (value != member)
            {
                P memberValue = member;
                member = value;
                auto ex = collectException!CheckConstraintException(checkConstraints());
                if (ex is null)
                {
                    notify!(name);
                }
                else
                {
                    member = memberValue;
                    throw ex;
                }
            }
        }
    }
/**
Initializes the keyed item by running *setClusteredIndex* and *checkConstraints*.
This should be in your constructor.
 */
    void initializeKeyedItem()
    {
        setClusteredIndex();
        checkConstraints();
    }

    static assert(!getColumns!(ClusteredIndexAttribute).empty,
                  "Must have columns with @UniqueConstraintColumn!\"" ~
                  ClusteredIndexAttribute.name ~ "\" to use this mixin.");

/**
Gets the properties of the class marked with @Attr.
 */
    static string[] getColumns(Attr)() @safe pure nothrow
    {
        string[] result;
        foreach(member; __traits(derivedMembers, T))
        {
            static if (member != "this")
            {
                foreach(ov; __traits(getOverloads, T, member))
                {
                    static if (hasUDA!(ov, Attr))
                    {
                        static if (__traits(isSame, Attr, PrimaryKeyColumn))
                        {
                            static assert(hasUDA!(ov, NotNull),
                                          "Primary key columns must have the NotNull" ~
                                          " attribute which is missing from " ~
                                          T.stringof ~ "." ~ member);
                        }
                        pragma(msg, T.stringof, ".", member, " is ", Attr.stringof);
                        result ~= member;
                    }
                }
            }
        }
        return result;
    }
/**
Gets the names given to the different UniqueConstraints
 */
    template UniqueConstraintStructNames(ClassName)
    {
/**
Takes a type tuple of class members and alias' as a typetuple with all unique constraint names
 */
        template Impl(T...)
        {
            static if (T.length == 0)
            {
                alias Impl = TypeTuple!();
            }
            else
            {
                static if (T[0] != "this")
                {
                    alias Impl = TypeTuple!(Overloads!(__traits(getOverloads, ClassName, T[0])), Impl!(T[1 .. $]));
                }
                else
                {
                    alias Impl = TypeTuple!(Impl!(T[1 .. $]));
                }
            }
        }
/**
Looks at the overloads for the functions.
 */
        template Overloads(S...)
        {
            static if (S.length == 0)
            {
                alias Overloads = TypeTuple!();
            }
            else
            {
                enum attributes = Get!(__traits(getAttributes, S[0]));
                static if (attributes == "")
                {
                    alias Overloads = TypeTuple!(Overloads!(S[1 .. $]));
                }
                else
                {
                    alias Overloads = TypeTuple!(attributes, Overloads!(S[1 .. $]));
                }
            }
        }
/**
Takes a members attributes and finds if it has one that starts with UniqueConstraint
 */
        template Get(P...)
        {
            static if (P.length == 0)
            {
                enum Get = "";
            }
            else
            {
                static if (isInstanceOf!(UniqueConstraintColumn, P[0]))
                {
                    alias Get = P[0].name;
                }
                else
                {
                    alias Get = Get!(P[1 .. $]);
                }
            }
        }
        alias UniqueConstraintStructNames = NoDuplicates!(Impl!(__traits(derivedMembers, ClassName)));
    }

/**
Returns a string full of the structs.
 */
    static string createType(string class_name)() @safe pure nothrow
    {
        string result = "public:\n";
        foreach(name; UniqueConstraintStructNames!(T))
        {
            static if (name == ClusteredIndexAttribute.name)
            {
                result ~= "    alias " ~ name ~ " = ClusteredIndex;\n";
                result ~= "    alias " ~ name ~ "_key = key;\n";
            }
            else
            {
                result ~= "    struct " ~ name ~ "\n";
                result ~= "    {\n";
                foreach(columnName; getColumns!(UniqueConstraintColumn!name)())
                {
                    result ~= "        typeof(" ~ class_name ~ "." ~ columnName ~ ") " ~ columnName ~ ";\n";
                }
                result ~= "        mixin generic_compare!(" ~ name ~ ");\n";
                result ~= "    }\n";
                result ~= "    " ~ name ~ " " ~ name ~ "_key() const @property nothrow pure @safe @nogc\n";
                result ~= "    {\n";
                result ~= "        auto _" ~ name ~ "_key = " ~ name ~ "();\n";
                foreach(columnName; getColumns!(UniqueConstraintColumn!name)())
                {
                    result ~= "        _" ~ name ~ "_key." ~ columnName ~ " = this._" ~ columnName ~ ";\n";
                }
                result ~= "        return _" ~ name ~ "_key;\n";
                result ~= "    }\n";
            }
        }
        return result;
    }
public:
/**
Read-only property telling if `this` contains changes.
Returns:
    true if `this` contains changes.
 */
    final bool containsChanges() const @property nothrow pure @safe @nogc
    {
        return _containsChanges;
    }
/**
Changes `this` to not contain changes. Should only
be used after a save.
 */
    final void markAsSaved() nothrow pure @safe @nogc
    {
        _containsChanges = false;
    }
/**
The signal used to emit changes that occur in `this`.
 */
    mixin Signal!(string, typeof(_key)) emitChange;

/**
Notifies `this` which property changed. If the property is
part of the clustered index then the clustered index is updated.
This also emits a signal with the property name that changed
along with the clustered index.
Params:
    propertyName = the property name that changed.
 */
    final void notify(string propertyName)()
    {
        _containsChanges = true;
        emitChange.emit(propertyName, _key);
        static if (getColumns!(ClusteredIndexAttribute).canFind(propertyName))
        {
            emitChange.emit("key", _key);
            setClusteredIndex();
        }
        foreach(name; Erase!(ClusteredIndexAttribute.name, UniqueConstraintStructNames!(T)))
        {
            static if (getColumns!(UniqueConstraintColumn!name).canFind(propertyName))
            {
                emitChange.emit(name ~ "_key", _key);
            }
        }
    }
    final void checkConstraints()
    {
        foreach(member; __traits(derivedMembers, T))
        {
            static if (member != "this")
            {
                foreach(ov; __traits(getOverloads, T, member))
                {
                    foreach(attr; __traits(getAttributes, ov))
                    {
                        static if (isInstanceOf!(CheckConstraint, attr))
                        {
                            enforceEx!(CheckConstraintException)(
                                attr.check(mixin("this." ~ member)),
                                (attr.name == "" ? "" : attr.name ~ " violation. ") ~
                                member ~ " failed its check with value " ~
                                mixin("this." ~ member).to!string());
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
    struct ClusteredIndex
    {
        // creates the members of the clustered key with appropriate type.
        mixin(function string()
              {
                  string result = "";
                  foreach(pkcolumn; getColumns!(ClusteredIndexAttribute))
                  {
                      result ~= "typeof(" ~ T.stringof ~ "." ~ pkcolumn ~ ") " ~ pkcolumn ~ ";\n";
                  }
                  return result;
              }());
        // adds the generic comparison for structs
        mixin generic_compare!(ClusteredIndex);
    }


/**
The clustered index property for the class.
Returns:
    The clustered index for the class.
 */
    final ClusteredIndex key() const @property nothrow pure @safe @nogc
    {
        return _key;
    }

/**
Sets the clustered index for `this`.
 */
    final void setClusteredIndex() nothrow pure @safe @nogc
    {
        auto new_key = ClusteredIndex();
        mixin(function string()
              {
                  string result = "";
                  foreach(pkcolumn; getColumns!(ClusteredIndexAttribute))
                  {
                      result ~= "new_key." ~ pkcolumn ~ " = this._" ~ pkcolumn ~ ";\n";
                  }
                  return result;
              }());
        this._key = new_key;
    }

    mixin(createType!(T.stringof));
}

///
unittest
{
    class Candy
    {
    private:
        string _name;
        int _ranking;
        string _brand;
    public:
        // name is the primary key
        @PrimaryKeyColumn @NotNull
        string name() const @property nothrow pure @safe @nogc
        {
            return _name;
        }
        void name(string value) @property
        {
            setter(_name, value);
        }
        // ranking must be unique among all the other records
        @UniqueConstraintColumn!("uc_Candy_ranking")
        int ranking() const @property nothrow pure @safe @nogc
        {
            return _ranking;
        }
        // making sure that ranking will always be above 0
        @CheckConstraint!(a => a > 0, "chk_Candy_ranking")
        void ranking(int value) @property
        {
            setter(_ranking, value);
        }
        string brand() const @property nothrow pure @safe @nogc
        {
            return _brand;
        }
        void brand(string value) @property
        {
            setter(_brand, value);
        }
        this(string name, immutable(int) ranking, string brand)
        {
            this._name = name;
            this._ranking = ranking;
            this._brand = brand;
            initializeKeyedItem();
        }
        Candy dup() const
        {
            return new Candy(this._name, this._ranking, this._brand);
        }

        // The primary key is now the clustered index as it is by default
        mixin KeyedItem!(typeof(this), PrimaryKeyColumn);
    }

    // source: http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/10.htm
    auto i = new Candy("Opal Fruit", 17, "Mars");

    assert(!i.containsChanges);

    auto pk = Candy.PrimaryKey("Opal Fruit");
    assert(i.key == pk);
    assert(i.key == i.PrimaryKey_key);
    assert(i.key.name == pk.name);

    auto j = new Candy("Opal Fruit", 16, "");
    // since name is the primary key i and j are equal because the names are equal
    assert(i.key == j.key);

    // in 1967 Opal Fruits came to America and changed its name
    i.name = "Starburst";
    assert(i.containsChanges);
    i.markAsSaved();
    assert(!i.containsChanges);

    // by changing the name it also changes the primary key
    assert(i.key != pk);
    assert(i.key != j.key);

    // below is what is created when you include the mixin KeyedItem
    enum candyStructs =
`public:
    alias PrimaryKey = ClusteredIndex;
    alias PrimaryKey_key = key;
    struct uc_Candy_ranking
    {
        typeof(Candy.ranking) ranking;
        mixin generic_compare!(uc_Candy_ranking);
    }
    uc_Candy_ranking uc_Candy_ranking_key() const @property nothrow pure @safe @nogc
    {
        auto _uc_Candy_ranking_key = uc_Candy_ranking();
        _uc_Candy_ranking_key.ranking = this._ranking;
        return _uc_Candy_ranking_key;
    }
`;
    assert(Candy.createType!(Candy.stringof) == candyStructs);

    import std.exception : assertThrown;
    import db_constraints.db_exceptions : CheckConstraintException;
    // we expect setting the ranking to 0 will result in an exception
    // since we labeled that column with
    // @CheckConstraint!(a => a > 0, "chk_Candy_ranking")
    assertThrown!CheckConstraintException(i.ranking = 0);
}
