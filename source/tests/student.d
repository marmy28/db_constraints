module tests.student;

import db_extensions;

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
class Students : BaseKeyedCollection!(Student)
{
public:
    this(Student[] items)
    {
        super(items);
    }
    this(Student item)
    {
        super(item);
    }
}

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
}
