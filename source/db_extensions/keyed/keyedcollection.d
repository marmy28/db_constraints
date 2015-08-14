module db_extensions.keyed.keyedcollection;

import std.signals;
import std.typecons;

import db_extensions.keyed.keyeditem;

abstract class BaseKeyedCollection(T)
{
private:
    bool _containsChanges;

    void add(T item)
    {
        // verify key is not already used
        // make PrimaryKey exception
        item.simple.connect(&notify);
        item.primary_key.connect(&keyChanged);
        this._items[item.key] = item;
    }
    void add(T[] items)
    {
        foreach(item; items)
        {
            this.add(item);
        }
    }
    void keyChanged(T.PrimaryKey oldPK, T.PrimaryKey newPK)
    {
        T item = this._items[oldPK].dup();
        this._items.remove(oldPK);
        this._items[newPK] = item;
    }
protected:
    T[T.PrimaryKey] _items;
    void markAsSaved() nothrow pure @safe @nogc
    {
        _containsChanges = false;
    }
public:
    bool containsChanges() @property nothrow pure @safe @nogc
    {
        return _containsChanges;
    }
    mixin Signal!(string);
    void notify(string propertyName)
    {
        _containsChanges = true;
        emit(propertyName);
        debug(signal) writeln("You changed ", propertyName);
    }
    ref auto opOpAssign(string op)(T item)
        if (op == "~")
    {
        this.add(item);
        notify("length");
    }
    ref T opIndex(T item) nothrow pure @safe
    {
        return this._items[item.key];
    }
    // ref T opIndex(T.PrimaryKey k)
    // {
    //     return this._items[k];
    // }
    auto opDispatch(string name, T...)(T t)
    {
        debug(dispatch) pragma(msg, "opDispatch", name);
        return mixin("this._items." ~ name ~ "(t)");
    }
    int opApply(int delegate(ref T) dg)
    {
        int result = 0;
        foreach(T i; this._items.values)
        {
            result = dg(i);
            if (result)
                break;
        }
        return result;
    }
    int opApply(int delegate(T.PrimaryKey, ref T) dg)
    {
        int result = 0;
        foreach(T i; this._items.values)
        {
            //ssert(i.key == j); make sure key and actual key are equal
            result = dg(i.key, i);
            if (result)
                break;
        }
        return result;
    }
    bool opBinaryRight(string op)(T item) nothrow pure @safe @nogc
        if (op == "in")
    {
        return this.contains(item);
    }
    size_t length() @property @safe nothrow pure
    {
        return this._items.length;
    }
    bool contains(T item) nothrow pure @safe @nogc
    {
        return this.contains(item.key);
    }
    bool contains(T.PrimaryKey k) nothrow pure @safe @nogc
    {
        auto i = (k in this._items);
        return (i !is null);
    }
    this(T item)
    {
        this.add(item);
    }
    this(T[] items)
    {
        this.add(items);
    }
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
    ref Student opIndex(string item)
    {
        auto i = Student.PrimaryKey(item);
        return this._items[i];
    }
    ref Student opIndex(Student.PrimaryKey k)
    {
        return this._items[k];
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
    assert(i["Tom"] == j);
    auto k = new Student("Jake", 5);
    assert(i["Tom"] != k);
}

unittest
{
    auto i = new Students(new Student("Tom", 7));
    auto j = new Student("Tom", 8);
    assert(i["Tom"] == j);
    auto k = new Student("Jake", 5);
    assert(i["Tom"] != k);
}

unittest
{
    auto i = new Students(new Student("Tom", 7));
    i ~= new Student("Jake", 5);
    assert(i.length == 2);
    foreach(item; i)
    {
        item.printInfo();
    }
    auto j = i["Tom"];
    j.cName = "Tommy";
    assert(i.length == 2);
    auto k = i["Tommy"];
    foreach(item; i)
    {
        item.printInfo();
    }
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
