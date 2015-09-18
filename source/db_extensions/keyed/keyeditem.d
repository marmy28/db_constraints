module db_extensions.keyed.keyeditem;

public import db_extensions.extra.constraints;

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
    import std.array;
    import std.signals;
private:
    bool _containsChanges;
    ClusteredIndex _key;

    import std.functional : unaryFun;
    import std.conv : to;

    template setter(alias check = "true", string name_ = __FUNCTION__)
        if (is(typeof(unaryFun!check)))
    {
        void setter(P)(ref P member, P value)
        {
            enum name = name_[std.string.lastIndexOf(name_, '.') + 1 .. $];
            if (unaryFun!check(value))
            {
                if (value != member)
                {
                    member = value;
                    notify(name);
                }
            }
            else
            {
                import db_extensions.extra.db_exceptions;
                throw new CheckConstraintException(name ~ " failed its check with value " ~ value.to!string());
            }
        }
    }

    static assert(!getColumns!(ClusteredIndexAttribute).empty,
                  "Must have columns with UniqueConstraintColumn!\"" ~
                  ClusteredIndexAttribute.name ~ "\" to use this mixin.");

    //Gets the properties of the class marked with @Attr. This is private.
    static string[] getColumns(Attr)()
    {
        import std.traits;
        import std.string;
        string[] result;
        foreach(member; __traits(derivedMembers, T))
        {
            // the following excluded members are
            // part of Signals and not the connected class
            static if (member != "connect" &&
                       member != "slot_t" &&
                       member != "slots" &&
                       member != "slots_idx" &&
                       member != "__dtor" &&
                       member != "unhook" &&
                       member != "disconnect" &&
                       member != "emit" &&
                       member != "this")
            {
                enum fullName = format(`%s.%s`, T.stringof, member);
                static if (hasUDA!(mixin(fullName), Attr))
                {
                    pragma(msg, fullName, " is ", Attr.stringof);
                    result ~= format(`%s`, member);
                }
            }
        }
        return result;
    }
    // Gets the names given to the different UniqueConstraints
    template UniqueConstraintStructNames(ClassName)
    {
        import std.typetuple;
        // Takes a type tuple of class members and alias' as a typetuple with all unique constraint names
        template Impl(T...)
        {
            static if (T.length == 0)
            {
                alias Impl = TypeTuple!();
            }
            else
            {
                import std.string : format;
                static if (T[0] != "connect" &&
                           T[0] != "slot_t" &&
                           T[0] != "slots" &&
                           T[0] != "slots_idx" &&
                           T[0] != "__dtor" &&
                           T[0] != "unhook" &&
                           T[0] != "disconnect" &&
                           T[0] != "emit" &&
                           T[0] != "this")
                {
                    enum fullName = format(`%s.%s`, ClassName.stringof, T[0]);
                    enum attributes =  Get!(__traits(getAttributes, mixin(fullName)));
                    static if (attributes == "")
                    {
                        alias Impl = TypeTuple!(Impl!(T[1 .. $]));
                    }
                    else
                    {
                        alias Impl = TypeTuple!(attributes, Impl!(T[1 .. $]));
                    }
                }
                else
                {
                    alias Impl = TypeTuple!(Impl!(T[1 .. $]));
                }
            }
        }
        // takes a members attributes and finds if it has one that starts with UniqueConstraint
        template Get(P...)
        {
            static if (P.length == 0)
            {
                enum Get = "";
            }
            else
            {
                import std.string;
                static if (P[0].stringof.startsWith("UniqueConstraint"))
                {
                    alias Get = P[0].name;
                }
                else static if (P[0].stringof.startsWith("CheckConstraint"))
                {
                    // does not appear to come in here
                    pragma(msg, P[0].stringof, " has it");
                    alias Get = Get!(P[1 .. $]);
                }
                else
                {
                    alias Get = Get!(P[1 .. $]);
                }
            }
        }
        import std.meta : NoDuplicates;
        alias UniqueConstraintStructNames = NoDuplicates!(Impl!(__traits(derivedMembers, ClassName)));
    }

    //Returns a string full of the structs.
    static string createType(string class_name)()
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
                result ~= "        import db_extensions.keyed.generickey;\n";
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
    bool containsChanges() const @property nothrow pure @safe @nogc
    {
        return _containsChanges;
    }
/**
Changes `this` to not contain changes. Should only
be used after a save.
 */
    void markAsSaved() nothrow pure @safe @nogc
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
    void notify(string propertyName)
    {
        import std.algorithm : canFind;
        import std.meta : Erase;
        _containsChanges = true;
        emitChange.emit(propertyName, _key);
        if (getColumns!(ClusteredIndexAttribute).canFind(propertyName))
        {
            emitChange.emit("key", _key);
            setClusteredIndex();
        }
        foreach(name; Erase!(ClusteredIndexAttribute.name, UniqueConstraintStructNames!(T)))
        {
            if (getColumns!(UniqueConstraintColumn!name).canFind(propertyName))
            {
                emitChange.emit(name ~ "_key", _key);
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
        import db_extensions.keyed.generickey;
        // creates the members of the clustered key with appropriate type.
        mixin(function string()
              {
                  import std.string;
                  string result = "";
                  foreach(pkcolumn; getColumns!(ClusteredIndexAttribute))
                  {
                      result ~= format("typeof(%s.%s) %s;", T.stringof, pkcolumn, pkcolumn);
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
    ClusteredIndex key() @property nothrow pure @safe @nogc
    {
        if (this._key == ClusteredIndex.init)
        {
            setClusteredIndex();
        }
        return _key;
    }

/**
Sets the clustered index for `this`.
 */
    void setClusteredIndex() nothrow pure @safe @nogc
    {
        auto new_key = ClusteredIndex();
        mixin(function string()
              {
                  import std.string;
                  string result = "";
                  foreach(pkcolumn; getColumns!(ClusteredIndexAttribute))
                  {
                      result ~= format("new_key.%s = this.%s;", pkcolumn, pkcolumn);
                  }
                  return result;
              }());
        this._key = new_key;
    }

/**
Compares `this` based on the clustered index.
Returns:
    true if the clustered index equal.
 */
    override bool opEquals(Object o) pure nothrow @nogc
    {
        auto rhs = cast(T)o;
        return (rhs !is null && this.key == rhs.key);
    }

/**
Compares `this` based on the clustered index if comparison is with the same class.
Returns:
    The comparison from the clustered index.
 */
    override int opCmp(Object o)
    {
        // Taking advantage of the automatically-maintained order of the types.
        if (typeid(this) != typeid(o))
        {
            return typeid(this).opCmp(typeid(o));
        }
        auto rhs = cast(T)o;
        return this.key.opCmp(rhs.key);
    }


/**
Gets the hash of the clustered index.
Returns:
    The hash of the clustered index.
 */
    override size_t toHash() const nothrow @safe
    {
        return _key.toHash();
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
        string name() const @property @PrimaryKeyColumn nothrow pure @safe @nogc
        {
            return _name;
        }
        void name(string value) @property
        {
            setter(_name, value);
        }
        int ranking() const @property nothrow pure @safe @nogc @UniqueConstraintColumn!("uc_Candy_ranking")
        {
            return _ranking;
        }
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
        this()
        {
            this._name = string.init;
            this._ranking = int.init;
            this._brand = string.init;
        }

        this(string name, immutable(int) ranking, string brand)
        {
            this._name = name;
            this._ranking = ranking;
            this._brand = brand;
        }
        Candy dup() const
        {
            return new Candy(this._name, this._ranking, this._brand);
        }
        // The primary key is now the clustered index
        mixin KeyedItem!(typeof(this), PrimaryKeyColumn);
    }

    // source: http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/10.htm
    auto i = new Candy("Opal Fruit", 17, "Mars");

    assert(!i.containsChanges);

    auto pk = Candy.PrimaryKey("Opal Fruit");
    assert(i.key == pk);
    assert(i.key == i.PrimaryKey_key);
    assert(i.key.name == pk.name);

    auto j = new Candy("Opal Fruit", 0, "");
    // since name is the clustered index i and j are equal because the names are equal
    assert(i == j);

    // in 1967 Opal Fruits came to America and changed its name
    i.name = "Starburst";
    assert(i.containsChanges);
    i.markAsSaved();
    assert(!i.containsChanges);

    // by changing the name it also changes the primary key
    assert(i.key != pk);
    assert(i != j);

    // below is what is created when you include the mixin KeyedItem
    enum candyStructs =
`public:
    alias PrimaryKey = ClusteredIndex;
    alias PrimaryKey_key = key;
    struct uc_Candy_ranking
    {
        typeof(Candy.ranking) ranking;
        import db_extensions.keyed.generickey;
        mixin generic_compare!(uc_Candy_ranking);
    }
    uc_Candy_ranking uc_Candy_ranking_key() const @property nothrow pure @safe @nogc
    {
        auto _uc_Candy_ranking_key = uc_Candy_ranking();
        _uc_Candy_ranking_key.ranking = this._ranking;
        return _uc_Candy_ranking_key;
    }
`;
    static assert(Candy.createType!(Candy.stringof) == candyStructs);
}
