module db_extensions.keyed.keyeditem;

import std.typecons : Flag, Yes;

/**
User-defined attribute that can be used with KeyedItem. KeyedItem
will create a struct made up of all of the properties marked with
@PrimaryKeyColumn() which can be used with KeyedCollection as
keys in an associative array.
 */
alias PrimaryKeyColumn = UniqueConstraintColumn!("PrimaryKey");
/**
User-defined attribute that can be used with KeyedItem. KeyedItem
will create a struct with name defined in the compile-time argument.
For example a property marked with @UniqueColumn!("uc_Person") will
be part of the struct uc_Person.
Bugs:
    Can only make one UniqueColumn struct.
 */
struct UniqueConstraintColumn(string pName)
{
    /// The name of the constraint which is the structs name.
    enum name = pName;
}

// @ForeignKey{Area.nAreaID, Cascade on delete, cascade on update}

/**
Use this in the singular class which would describe a row in your
database.
Params:
    T = the type of the class this is mixed into.
    ClusteredKeyAttribute = the attribute associated with the clustered key.
    The default is @PrimaryKeyColumn.
 */
mixin template KeyedItem(T, ClusteredKeyAttribute = PrimaryKeyColumn)
{
    import std.array;
    import std.signals;
private:
    bool _containsChanges;
    ClusteredKey _key;

/**
Gets the properties of the class marked with @Attr. This is private.
Deprecated:
    This will be phased out soon. Instead I will use get_Columns.
    Currently only the primary key uses this.
 */
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

    template UniqueConstraintStructNames(ClassName)
    {
        import std.typetuple;
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
                else
                {
                    alias Get = Get!(P[1 .. $]);
                }
            }
        }
        import std.meta : NoDuplicates;
        alias UniqueConstraintStructNames = NoDuplicates!(Impl!(__traits(derivedMembers, ClassName)));
    }

/**
Returns a string full of the structs. This is private.
Bugs:
    Currently under development.
 */
    static string createType(string class_name)()
    {
        string result = "";
        foreach(name; UniqueConstraintStructNames!(T))
        {
            static if (name == ClusteredKeyAttribute.name)
            {
                result ~= "public:\n";
                result ~= "    alias " ~ name ~ " = ClusteredKey;\n";
                result ~= "    alias " ~ name ~ "_key = key;\n";
            }
            else
            {
                // result ~= "private:\n";
                // result ~= "    " ~ name ~ " _" ~ name ~ "_key;\n";
                result ~= "public:\n";
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
    bool containsChanges() @property nothrow pure @safe @nogc
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

    mixin Signal!(string, typeof(_key)) emitChange;

/**
Notifies `this` which property changed. If the property is
part of the clustered key then the clustered key is updated.
This also emits a signal with the property name that changed
along with the clustered key.
Params:
    propertyName = the property name that changed.
 */
    void notify(string propertyName)
    {
        import std.algorithm : canFind;
        _containsChanges = true;
        emitChange.emit(propertyName, _key);
        if (getColumns!(ClusteredKeyAttribute).canFind(propertyName))
        {
            emitChange.emit("key", _key);
            setClusteredKey();
        }
    }

/**
Clustered key struct created at compile-time.
This is used to compare classes. The members
are the members of the class marked with the
attribute selected as the Clustered Key.
 */
    struct ClusteredKey
    {
        import db_extensions.keyed.generickey;
        // creates the members of the clustered key with appropriate type.
        mixin(function string()
              {
                  import std.string;
                  string result = "";
                  foreach(pkcolumn; getColumns!(ClusteredKeyAttribute))
                  {
                      result ~= format("typeof(%s.%s) %s;", T.stringof, pkcolumn, pkcolumn);
                  }
                  return result;
              }());
        // adds the generic comparison for structs
        mixin generic_compare!(ClusteredKey);
    }


/**
The clustered key property for the class.
Returns:
    The clustered key for the class.
 */
    ClusteredKey key() const @property nothrow pure @safe @nogc
    {
        return _key;
    }

/**
Sets the clustered key for `this`.
 */
    void setClusteredKey()
    {
        auto new_key = ClusteredKey();
        mixin(function string()
              {
                  import std.string;
                  string result = "";
                  foreach(pkcolumn; getColumns!(ClusteredKeyAttribute))
                  {
                      result ~= format("new_key.%s = this.%s;", pkcolumn, pkcolumn);
                  }
                  return result;
              }());
        this._key = new_key;
    }
    deprecated("Use setClusteredKey instead.")
    alias setPrimaryKey = setClusteredKey;
/**
Compares `this` based on the clustered key.
Returns:
    true if the clustered keys equal.
 */
    override bool opEquals(Object o) const pure nothrow @nogc
    {
        auto rhs = cast(immutable T)o;
        return (rhs !is null && this.key == rhs.key);
    }

/**
Compares `this` based on the clustered key if comparison is with the same class.
Returns:
    The comparison from the clustered key.
 */
    override int opCmp(Object o) const
    {
        // Taking advantage of the automatically-maintained order of the types.
        if (typeid(this) != typeid(o))
        {
            return typeid(this).opCmp(typeid(o));
        }
        auto rhs = cast(const T)o;
        return this.key.opCmp(rhs.key);
    }


/**
Gets the hash of the clustered key.
Returns:
    The hash of the clustered key.
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
            if (value != _name)
            {
                _name = value;
                notify("name");
            }
        }
        int ranking() const @property nothrow pure @safe @nogc @UniqueConstraintColumn!("uc_Candy_ranking")
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
        this()
        {
            this._name = string.init;
            this._ranking = int.init;
            this._brand = string.init;
            setClusteredKey();
        }

        this(string name, immutable(int) ranking, string brand)
        {
            this._name = name;
            this._ranking = ranking;
            this._brand = brand;
            // do not forget to set the clustered key
            setClusteredKey();
        }
        Candy dup() const
        {
            return new Candy(this._name, this._ranking, this._brand);
        }
        // The primary key is now the clustered key
        mixin KeyedItem!(typeof(this), PrimaryKeyColumn);
    }

    // source: http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/10.htm
    auto i = new Candy("Opal Fruit", 17, "Mars");

    assert(!i.containsChanges);

    auto pk = Candy.ClusteredKey("Opal Fruit");
    assert(i.key == pk);
    assert(i.key == i.PrimaryKey_key);
    assert(i.key.name == pk.name);

    auto j = new Candy("Opal Fruit", 0, "");
    // since name is the clustered key i and j are equal because the names are equal
    assert(i == j);

    // in 1967 Opal Fruits came to America and changed its name
    i.name = "Starburst";
    assert(i.containsChanges);
    i.markAsSaved();
    assert(!i.containsChanges);

    // by changing the name it also changes the clustered key
    assert(i.key != pk);
    assert(i != j);
}
