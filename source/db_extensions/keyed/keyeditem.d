module db_extensions.keyed.keyeditem;

import std.typecons : Flag, Yes;

/**
User-defined attribute that can be used with KeyedItem. KeyedItem
will create a struct made up of all of the properties marked with
@PrimaryKeyColumn() which can be used with KeyedCollection as
keys in an associative array.
 */
struct PrimaryKeyColumn
{
    /// PrimaryKeyColumn must have the name PrimaryKey.
    string name = "PrimaryKey";
    /// Cannot change the name of `this`.
    @disable this(string pName);
}
/**
User-defined attribute that can be used with KeyedItem. KeyedItem
will create a struct with name defined in the compile-time argument.
For example a property marked with @UniqueColumn!("uc_Person") will
be part of the struct uc_Person.
Bugs:
    Can only make one UniqueColumn struct.
 */
struct UniqueColumn(string constraint_name)
{
	enum name = constraint_name;
}

// @ForeignKey{Area.nAreaID, Cascade on delete, cascade on update}

/**
Use this in the singular class which would describe a row in your
database.
 */
mixin template KeyedItem(T)
{
    import std.array;
    import std.signals;
private:
    bool _containsChanges;
    PrimaryKey _key;

/**
Gets the properties of the class marked with @Attr.
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
                       member != "emit")
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
Gets the properties of the class that start with Attr.
Returns:
    An associative array with the structs name as the key and an
    array of strings of the structs members.
Bugs:
    Currently this is under development.
 */
    static string[][string] get_Columns(string Attr)()
    {
        import std.string : format;
        import std.array;
        import std.algorithm : startsWith;
        string[][string] result;
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
                       member != "emit")
            {
                enum fullName = format(`%s.%s`, T.stringof, member);
                foreach(attr; __traits(getAttributes, mixin(fullName)))
                {
                    static if (attr.stringof.startsWith(Attr))
                    {
                        pragma(msg, fullName, " is ", attr.name);
                        result[attr.name] ~= format("%s", member);
                    }
                }
            }
        }
        return result;
    }
/**
Returns a string full of the structs.
Bugs:
    Currently under development.
 */
    static string createType(string class_name, string Attr)()
    {
        string result = "";
        enum aa = get_Columns!(Attr)();
        // currently fails if there is more than one key...
        foreach(key; aa.keys)
        {
            result ~= "private:\n";
            result ~= "    " ~ key ~ " _" ~ key ~ "_key;\n";
            result ~= "public:\n";
            result ~= "    struct " ~ key ~ "\n";
            result ~= "    {\n";
            foreach(columnName; aa[key])
            {
                result ~= "        typeof(" ~ class_name ~ "." ~ columnName ~ ") " ~ columnName ~ ";\n";
            }
            result ~= "        import db_extensions.keyed.generickey;\n";
            result ~= "        mixin generic_compare!(" ~ key ~ ");\n";
            result ~= "    }\n";
            result ~= "    " ~ key ~ " " ~ key ~ "_key() const @property nothrow pure @safe @nogc\n";
            result ~= "    {\n";
            result ~= "        return _" ~ key ~ "_key;\n";
            result ~= "    }\n";
        }
        return result;
    }
protected:
/**
Changes `this` to not contain changes. Should only
be used after a save.
 */
    void markAsSaved() nothrow pure @safe @nogc
    {
        _containsChanges = false;
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

    static assert(!getColumns!(PrimaryKeyColumn).empty, "Must have primary key columns to use this mixin.");

    mixin Signal!(string) simple;
    mixin Signal!(PrimaryKey, PrimaryKey) primary_key;

/**
Notifies `this` which property changed. If the property is
part of the primary key then the primary key is updated.
This also emits a signal with the property name that changed.
 */
    void notify(string propertyName)
    {
        import std.algorithm : canFind;
        if (getColumns!(PrimaryKeyColumn).canFind(propertyName))
        {
            setPrimaryKey();
        }
        _containsChanges = true;
        simple.emit(propertyName);
    }

    // this struct is made at compile time from the class
    struct PrimaryKey
    {
        // make invariant for not null
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
        mixin generic_compare!(PrimaryKey);
    }

    PrimaryKey key() const @property nothrow pure @safe @nogc
    {
        return _key;
    }
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
        if (this._key != PrimaryKey.init)
        {
            primary_key.emit(this._key, new_key);
        }
        this._key = new_key;
    }
    override bool opEquals(Object o) const pure nothrow @nogc
    {
        auto rhs = cast(immutable T)o;
        return (rhs !is null && this.key == rhs.key);
    }
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
    override size_t toHash() const nothrow @safe
    {
        return _key.toHash();
    }

    //pragma(msg, createType!(T.stringof, "UniqueColumn!"));
    // Can only produce 1 unique struct since compile time does not work with associative arrays.
    mixin(createType!(T.stringof, "UniqueColumn!"));
}

version(unittest)
class Student
{
private:
    string _cName;
    int _nNumClasses;
public:
    string cName() const @property @PrimaryKeyColumn() nothrow pure @safe @nogc
    {
        return _cName;
    }
    void cName(immutable(char)[] value) @property
    {
        if (value != _cName)
        {
            _cName = value;
            notify("cName");
        }
    }
    int nNumClasses() const @property @UniqueColumn!("uc_Student") nothrow pure @safe @nogc
    {
        return _nNumClasses;
    }
    void nNumClasses(immutable(int) value) @property
    {
        if (value != _nNumClasses)
        {
            _nNumClasses = value;
            notify("nNumClasses");
        }
    }

    this(immutable(char)[] pcName, immutable(int) pnNumClasses)
    {

        this._cName = pcName;
        this._nNumClasses = pnNumClasses;
        setPrimaryKey();
    }
    Student dup() const
    {
        return new Student(this._cName, this._nNumClasses);
    }

    bool isValid() const nothrow pure @safe @nogc
    {
        if (this._cName.length > 13)
        {
            return false;
        }
        return true;
    }
    void printInfo()
    {
        import std.stdio: writeln;
        writeln("cName = ", cName,
                ", nNumClasses = ", nNumClasses);
    }
    mixin KeyedItem!(typeof(this));
}


unittest
{
    auto i = new Student("Tom", 8);
    assert(i.isValid);
}
unittest
{
    auto i = new Student("Tom", 8);
    assert(!i.containsChanges);
    i.cName = "What";
    assert(i.containsChanges);
    i.markAsSaved();
    assert(!i.containsChanges);
}
unittest
{
    auto i = new Student("Tom", 0);
    auto j = new Student("Tom", 7);
    assert(i == j);
}
unittest
{
    auto i = new Student("Tom", 0);
    auto j = new Student("Jake", 7);
    assert(i != j);
    assert(i > j);
}
unittest
{
    auto i = Student.PrimaryKey("Jean");
    assert(i.cName == "Jean");
    assert(typeid(i.cName) == typeid(string));
    auto j = new Student("Tom", 8);
    assert(i != j.key);
    j.cName = "Jean";
    assert(i == j.key);
}
unittest
{
    auto i = new Student("Tom", 0);
    auto j = new Student("Jake", 0);
    assert(i.key != j.key);
    assert(i != j);
    assert(i.uc_Student_key == j.uc_Student_key);
}
