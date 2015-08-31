module db_extensions.keyed.generickey;

/**
Used in KeyedItem for the generated structs.
This allows the struct to be used as a key
in an associative array.
 */
mixin template generic_compare(T)
    if (is(T == struct))
{
/**
Gets the hash code of the struct by looping over the members.
 */
    size_t toHash() const nothrow @safe
    {
        size_t result;
        foreach(i, dummy; this.tupleof)
        {
            if (i == 0)
            {
                result = typeid(this.tupleof[i]).getHash(&this.tupleof[i]);
            }
            else
            {
                result ^= typeid(this.tupleof[i]).getHash(&this.tupleof[i]);
            }
        }
        return result;
    }
/**
Checks each member to determine if the structs are equal.
 */
    bool opEquals(inout(T) pk) const pure nothrow @nogc
    {
        bool result;
        foreach(i, dummy; pk.tupleof)
        {
            if (this.tupleof[i] == pk.tupleof[i])
            {
                result = true;
                continue;
            }
            else if (this.tupleof[i] != pk.tupleof[i])
            {
                result = false;
                break;
            }
            assert(0);
        }
        return result;
    }
/**
Compares each member and returns the result.
 */
    int opCmp(inout(T) pk) const pure nothrow @nogc @safe
    {
        int result;
        foreach(i, dummy; pk.tupleof)
        {
            if (this.tupleof[i] > pk.tupleof[i])
            {
                result = 1;
                break;
            }
            else if (this.tupleof[i] < pk.tupleof[i])
            {
                result = -1;
                break;
            }
            else if (this.tupleof[i] == pk.tupleof[i])
            {
                result = 0;
                continue;
            }
            assert(0);
        }
        return result;
    }
}
/**
Bugs:
    Does not work. Do not use this.
 */
template UniqueConstraintStructNames(ClassName)
{
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
                auto attributes =  Get!(__traits(getAttributes, mixin(fullName)));
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
            static if (P[0].stringof.startsWith("UniqueConstraint"))
            {
                enum Get = P[0].name;
            }
            else
            {
                enum Get = Get!(P[1 .. $]);
            }
        }
    }
    alias UniqueConstraintStructNames = Impl!(__traits(derivedMembers, ClassName));
    //     sort(result);
    //     return uniq(result).array;
    // }
    // alias UniqueConstraintStructNames = getStructNames();
}
