module tests.student;

import db_constraints;

version(unittest)
class Student
{
private:
    string _cName;
    int _nNumClasses;
public:
    @PrimaryKeyColumn @NotNull
    @property string cName() const nothrow pure @safe @nogc
    {
        return _cName;
    }
    @CheckConstraint!("a.length < 13")
    @property void cName(immutable(char)[] value)
    {
        setter(_cName, value);
    }
    @property int nNumClasses() const nothrow pure @safe @nogc
    {
        return _nNumClasses;
    }
    @UniqueConstraintColumn!("uc_Student")
    @property void nNumClasses(immutable(int) value)
    {
        setter(_nNumClasses, value);
    }

    this(string pcName, immutable(int) pnNumClasses)
    {

        this._cName = pcName;
        this._nNumClasses = pnNumClasses;

        initializeKeyedItem();
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
    override string toString()
    {
        return this.cName;
    }
    override int opCmp(Object o) const
    {
        if (typeid(this) != typeid(o))
        {
            return typeid(this).opCmp(typeid(o));
        }
        auto rhs = cast(immutable Student)o;
        return this.key.opCmp(rhs.key);
    }
    override bool opEquals(Object o) const pure nothrow @nogc
    {
        auto rhs = cast(immutable Student)o;
        return (rhs !is null && this.key == rhs.key);
    }
    mixin KeyedItem!();
}

unittest
{
    auto i = new Student("Tom", 8);
    assert(i.isValid);
}
///
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
    auto j = new Student("Tom", 7);
    assert(i == j);
}
unittest
{
    auto i = new Student("Tom", 0);
    auto j = new Student("Jake", 0);
    assert(i.key != j.key);
    assert(i != j);
    assert(i.uc_Student_key == j.uc_Student_key);
}


version(unittest)
alias Students = BaseKeyedCollection!(Student);

unittest
{
    auto i = new Students(new Student("Tom", 7));
    assert(i.length == 1);
}
unittest
{
    auto i = new Students(new Student("Tom", 7));
    assert(!i.containsChanges);
    i ~= new Student("Jon", 8);
    assert(i.length == 2);
    assert(i.containsChanges);
    i.markAsSaved();
    assert(!i.containsChanges);
}
unittest
{
    auto i = new Students(new Student("Tom", 7));
    auto j = new Student("Tom", 8);
    assert(i[cast(Student.PrimaryKey)"Tom"] == j);
    auto k = new Student("Jake", 5);
    assert(i[Student.PrimaryKey("Tom")] != k);
}

unittest
{
    auto i = new Students(new Student("Tom", 7));
    auto j = new Student("Tom", 8);
    auto Tom = Student.PrimaryKey("Tom");
    assert(i[Tom] == j);
    auto k = new Student("Jake", 5);
    assert(i[Tom] != k);
}

unittest
{
    auto i = new Students(new Student("Tom", 7));
    i ~= new Student("Jake", 5);
    assert(i.length == 2);
    auto Tom = Student.PrimaryKey("Tom");
    assert(Tom in i);
    auto j = i[Tom];
    j.cName = "Tommy";
    assert(i.length == 2);
    auto Tommy = Student.PrimaryKey("Tommy");
    assert(Tommy in i);
    auto k = i[Tommy];
    auto l = new Student("Tommy", 7);
    assert(l == k);
}

unittest
{
    auto i = new Students(new Student("Tom", 7));
    i ~= new Student("Jake", 5);
    foreach(mykey, myvalue; i)
    {
        assert(i[mykey] == myvalue);
    }
    auto j = new Student("Jake", 5);
    assert(i.contains(j.key));
    assert(i.contains(j));
    assert(j in i);

    import std.exception : assertThrown;
    assertThrown!UniqueConstraintException(i ~= j);
}

unittest
{
    auto i = new Students(new Student("Tom", 7));
    auto jake = new Student("Jake", 7);
    import std.exception : assertThrown;
    assertThrown!UniqueConstraintException(i.add(jake));
    jake.nNumClasses = 5;
    i.add(jake);
    assertThrown!UniqueConstraintException(i["Jake"].nNumClasses = 7);
}

unittest
{
    auto i = new Students(new Student("Tom", 7));
    auto jake = new Student("Jake", 7);
    import std.exception : assertThrown, assertNotThrown;
    assertThrown!UniqueConstraintException(i.add(jake));
    jake.nNumClasses = 5;
    i.add(jake);
    assertNotThrown!UniqueConstraintException(i["Jake"].nNumClasses = 6);
    assertThrown!KeyedException(i["Sup"].nNumClasses = 9);
}

unittest
{
    import std.exception : assertThrown, assertNotThrown;

    auto tom1 = new Student("Tom", 7);
    auto tom2 = new Student("Tom", 7);
    auto i = new Students(tom1);
    assert(i.length == 1);
    string j;
    assert(i.violatesUniqueConstraints(tom2, j));
    assert(j == "PrimaryKey, uc_Student");
    assert(!i.violatesUniqueConstraints(tom1));
    assertNotThrown!UniqueConstraintException(i.add(tom1));
    assertThrown!UniqueConstraintException(i.add(tom2));
    assert(i.length == 1);
    tom2.cName = "James";
    assertThrown!UniqueConstraintException(i.add(tom2));
    i.enforceConstraints = Enforce.clusteredUnique;
    assertNotThrown!UniqueConstraintException(i.add(tom2));
    assert(i.length == 2);
    foreach(item; i)
    {
        assert(i[item.key] == item);
    }
    auto tom3 = new Student("Tom", 2);
    assertThrown!UniqueConstraintException(i.add(tom3));
}
