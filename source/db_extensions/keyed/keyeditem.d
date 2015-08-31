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
 */
mixin template KeyedItem(T, string ClusteredName = PrimaryKeyColumn.name)
{
    import std.array;
    import std.signals;
private:
    bool _containsChanges;
    PrimaryKey _key;

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

/**
Gets the properties of the class that start with Attr. This is private.
Returns:
    An associative array with the structs name as the key and an
    array of strings of the structs members.
Bugs:
    Currently this is under development.
Notes:
    Look into what phobos traits does with
    TypeTuple and see if I can do that here
    since arrays are not working at compile time.
 */
    static auto getStructNames(string AttrName)()
    {
        import std.algorithm : startsWith, sort, uniq;
        import std.string : format;
        string[] result;
        import std.typetuple;
        auto TL = TypeTuple!();
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
                foreach(attr; __traits(getAttributes, mixin(fullName)))
                {
                    static if (attr.stringof.startsWith(AttrName))
                    {
                        result ~= attr.name;
                    }
                }
            }
        }
        sort(result);
        return uniq(result).array;
    }
/**
Returns a string full of the structs. This is private.
Bugs:
    Currently under development. Does not work at all.
 */
    // static string createType(string class_name)()
    // {
    //     string result = "";
    //     import db_extensions.keyed.generickey;
    //     foreach(name; UniqueConstraintStructNames!(T))
    //     {
    //         result ~= "private:\n";
    //         static if (name == ClusteredName)
    //         {
    //             result ~= "    " ~ name ~ " _key;\n";
    //         }
    //         else
    //         {
    //             result ~= "    " ~ name ~ " _" ~ name ~ "_key;\n";
    //         }
    //         result ~= "public:\n";
    //         result ~= "    struct " ~ name ~ "\n";
    //         result ~= "    {\n";
    //         foreach(columnName; getColumns!(UniqueConstraintColumn!name)())
    //         {
    //             result ~= "        typeof(" ~ class_name ~ "." ~ columnName ~ ") " ~ columnName ~ ";\n";
    //         }
    //         result ~= "        import db_extensions.keyed.generickey;\n";
    //         result ~= "        mixin generic_compare!(" ~ name ~ ");\n";
    //         result ~= "    }\n";
    //         static if (name == ClusteredName)
    //         {
    //             result ~= "    " ~ name ~ " key() const @property nothrow pure @safe @nogc\n";
    //             result ~= "    {\n";
    //             result ~= "        return _key;\n";
    //             result ~= "    }\n";
    //         }
    //         else
    //         {
    //             result ~= "    " ~ name ~ " " ~ name ~ "_key() const @property nothrow pure @safe @nogc\n";
    //             result ~= "    {\n";
    //             result ~= "        return _" ~ name ~ "_key;\n";
    //             result ~= "    }\n";
    //         }
    //     }
    //     return result;
    // }
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
part of the primary key then the primary key is updated.
This also emits a signal with the property name that changed.
Params:
    propertyName = the property name that changed.
 */
    void notify(string propertyName)
    {
        import std.algorithm : canFind;
        _containsChanges = true;
        emitChange.emit(propertyName, _key);
        if (getColumns!(PrimaryKeyColumn).canFind(propertyName))
        {
            emitChange.emit("key", _key);
            setPrimaryKey();
        }
    }

/**
Primary key struct created at compile-time.
This is used to compare classes. The members
are the members of the class marked with
@PrimaryKeyColumn.
 */
    struct PrimaryKey
    {
        import db_extensions.keyed.generickey;
        // creates the members of the primary key with appropriate type.
        mixin(function string()
              {
                  import std.string;
                  string result = "";
                  foreach(pkcolumn; getColumns!(PrimaryKeyColumn))
                  {
                      result ~= format("typeof(%s.%s) %s;", T.stringof, pkcolumn, pkcolumn);
                  }
                  return result;
              }());
        // adds the generic comparison for structs
        mixin generic_compare!(PrimaryKey);
    }

/**
The primary key property for the class.
Returns:
    The primary key for the class.
 */
    typeof(_key) key() const @property nothrow pure @safe @nogc
    {
        return _key;
    }

/**
Sets the primary key for `this`. This also emits a
signal if it is not the first time setting the
primary key for `this`.
 */
    void setPrimaryKey()
    {
        auto new_key = PrimaryKey();
        mixin(function string()
              {
                  import std.string;
                  string result = "";
                  foreach(pkcolumn; getColumns!(PrimaryKeyColumn))
                  {
                      result ~= format("new_key.%s = this.%s;", pkcolumn, pkcolumn);
                  }
                  return result;
              }());
        this._key = new_key;
    }
/**
Compares `this` based on the primary key.
Returns:
    true if the primary keys equal.
 */
    override bool opEquals(Object o) const pure nothrow @nogc
    {
        auto rhs = cast(immutable T)o;
        return (rhs !is null && this.key == rhs.key);
    }

/**
Compares `this` based on the primary key if comparison is with the same class.
Returns:
    The comparison from the primary key.
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
Gets the hash of the primary key.
Returns:
    The hash of the primary key.
 */
    override size_t toHash() const nothrow @safe
    {
        return _key.toHash();
    }
    // pragma(msg, getStructNames!("UniqueConstraintColumn")());
    // pragma(msg,createType!(T.stringof));
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

        this(string name, immutable(int) ranking, string brand)
        {
            this._name = name;
            this._ranking = ranking;
            this._brand = brand;
            // do not forget to set the primary key
            setPrimaryKey();
        }
        Candy dup() const
        {
            return new Candy(this._name, this._ranking, this._brand);
        }
        mixin KeyedItem!(typeof(this));
    }

    // source: http://www.bloomberg.com/ss/09/10/1021_americas_25_top_selling_candies/10.htm
    auto i = new Candy("Opal Fruit", 17, "Mars");

    assert(!i.containsChanges);

    auto pk = Candy.PrimaryKey("Opal Fruit");
    assert(i.key == pk);
    assert(i.key.name == pk.name);

    auto j = new Candy("Opal Fruit", 0, "");
    // since name is the primary key i and j are equal because the names are equal
    assert(i == j);

    // in 1967 Opal Fruits came to America and changed its name
    i.name = "Starburst";
    assert(i.containsChanges);
    i.markAsSaved();
    assert(!i.containsChanges);

    // by changing the name it also changes the primary key
    assert(i.key != pk);
    assert(i != j);
}
