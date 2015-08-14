module db_extensions.keyed.keyeditem;

//import std.signals;
//import std.traits;
//import std.stdio;
//import std.string;
//import std.array;
import std.typecons : Flag, No;
struct PrimaryKeyColumn {};
struct UniqueColumn {};

// @ForeignKey{Area.nAreaID, Cascade on delete, cascade on update}

mixin template KeyedItem(T, Flag!"useUniqueColumn" useUniqueColumn = Flag!"useUniqueColumn".no)
{
    import std.array;
    import std.signals;
private:
    bool _containsChanges;
    PrimaryKey _key;

/**
   Gets the properties of the class marked with @Attr.
   This is used to generate the primary key struct and/or the Unique column struct.
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
protected:
    void markAsSaved() nothrow pure @safe @nogc
    {
        _containsChanges = false;
    }
public:
    bool containsChanges() @property nothrow pure @safe @nogc
    {
        return _containsChanges;
    }

    static assert(!getColumns!(PrimaryKeyColumn).empty, "Must have primary key columns to use this mixin.");

    mixin Signal!(string) simple;
    mixin Signal!(PrimaryKey, PrimaryKey) primary_key;
    void notify(string propertyName)
    {
        import std.algorithm : canFind;
        if (getColumns!(PrimaryKeyColumn).canFind(propertyName))
        {
            setPrimaryKey();
        }
        static if (useUniqueColumn)
        {
            if (getColumns!(UniqueColumn).canFind(propertyName))
            {
                setUnique();
            }
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

    static if (useUniqueColumn)
    {
        static assert(!getColumns!(UniqueColumn).empty, "Must have unique columns to use the unique part of the mixin.");
    private:
        Unique _unique;
    public:
        mixin Signal!(Unique, Unique) unique_constraint;
        struct Unique
        {
            import db_extensions.keyed.generickey;
            // creates the members of the unique constraint with appropriate type.
            mixin(function string()
                  {
                      import std.string;
                      string result = "";
                      foreach(uqcolumn; getColumns!(UniqueColumn))
                      {
                          result ~= format("typeof(%s.%s) %s;", T.stringof, uqcolumn, uqcolumn);
                      }
                      return result;
                  }());
            mixin generic_compare!(Unique);
        }

        Unique unique() const @property nothrow pure @safe @nogc
        {
            return _unique;
        }
        void setUnique()
        {
            auto new_unique = Unique();
            mixin(function string()
                  {
                      import std.string;
                      string result = "";
                      foreach(uqcolumn; getColumns!(UniqueColumn))
                      {
                          result ~= format("new_unique.%s = this.%s;", uqcolumn, uqcolumn);
                      }
                      return result;
                  }());
            if (this._unique != Unique.init)
            {
                unique_constraint.emit(this._unique, new_unique);
            }
            this._unique = new_unique;
        }
    }
}

version(unittest)
class Student
{
private:
    string _cName;
    int _nNumClasses;
public:
    string cName() const @property @PrimaryKeyColumn nothrow pure @safe @nogc
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
    int nNumClasses() const @property nothrow pure @safe @nogc
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
    mixin KeyedItem!(typeof(this), No.useUniqueColumn);
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
