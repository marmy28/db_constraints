module db_extensions.keyed.keyedcollection;

import std.signals;
import std.typecons;

import db_extensions.keyed.keyeditem;
import tests.student;

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
    ref T opIndex(T.PrimaryKey k)
    {
        return this._items[k];
    }
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
    bool opBinaryRight(string op)(T.PrimaryKey item) nothrow pure @safe @nogc
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



