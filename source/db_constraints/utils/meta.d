module db_constraints.utils.meta;

import std.meta : NoDuplicates;
import std.typetuple : TypeTuple;
import std.traits : isInstanceOf, hasUDA;

import db_constraints.constraints;
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
    final size_t toHash() const nothrow @safe
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
    final bool opEquals(inout(T) pk) const pure nothrow @nogc @safe
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
    final int opCmp(inout(T) pk) const pure nothrow @nogc @safe
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
Gets the names given to the different UniqueConstraints
 */
template UniqueConstraintStructNames(ClassName)
{
/**
Takes a type tuple of class members and alias' as a typetuple with all unique constraint names
*/
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            alias Impl = TypeTuple!();
        }
        else
        {
            static if (__traits(compiles, __traits(getMember, ClassName, T[0])))
            {
                alias Impl = TypeTuple!(Overloads!(__traits(getOverloads, ClassName, T[0])), Impl!(T[1 .. $]));
            }
            else
            {
                alias Impl = TypeTuple!(Impl!(T[1 .. $]));
            }
        }
    }
/**
Looks at the overloads for the functions.
*/
    template Overloads(S...)
    {
        static if (S.length == 0)
        {
            alias Overloads = TypeTuple!();
        }
        else
        {
            enum attributes = Get!(__traits(getAttributes, S[0]));
            static if (attributes == "")
            {
                alias Overloads = TypeTuple!(Overloads!(S[1 .. $]));
            }
            else
            {
                alias Overloads = TypeTuple!(attributes, Overloads!(S[1 .. $]));
            }
        }
    }
/**
Takes a members attributes and finds if it has one that starts with UniqueConstraint
*/
    template Get(P...)
    {
        static if (P.length == 0)
        {
            enum Get = "";
        }
        else
        {
            static if (isInstanceOf!(UniqueConstraintColumn, P[0]))
            {
                alias Get = P[0].name;
            }
            else
            {
                alias Get = Get!(P[1 .. $]);
            }
        }
    }
    alias UniqueConstraintStructNames = NoDuplicates!(Impl!(__traits(derivedMembers, ClassName)));
}

/**
Gets the properties of ClassName marked with @attribute.
 */
template GetMembersWithUDA(ClassName, attribute)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            alias Impl = TypeTuple!();
        }
        else
        {
            static if (__traits(compiles, __traits(getMember, ClassName, T[0])) &&
                       Overloads!(__traits(getOverloads, ClassName, T[0])))
            {
                alias Impl = TypeTuple!(T[0], Impl!(T[1 .. $]));
            }
            else
            {
                alias Impl = TypeTuple!(Impl!(T[1 .. $]));
            }
        }
    }
    template Overloads(P...)
    {
        static if (P.length == 0)
        {
            enum Overloads = false;
        }
        else static if (hasUDA!(P[0], attribute))
        {
            static if (__traits(isSame, attribute, PrimaryKeyColumn))
            {
                static assert(hasUDA!(P[0], NotNull),
                              "Primary key columns must have the NotNull" ~
                              " attribute which is missing from the class " ~
                              ClassName.stringof);
            }
            enum Overloads = true;
        }
        else
        {
            alias Overloads = Overloads!(P[1 .. $]);
        }
    }

    alias GetMembersWithUDA = NoDuplicates!(Impl!(__traits(derivedMembers, ClassName)));
}


template HasMembersWithUDA(ClassName, attribute)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            enum Impl = false;
        }
        else
        {
            static if (__traits(compiles, __traits(getMember, ClassName, T[0])) &&
                       Overloads!(__traits(getOverloads, ClassName, T[0])))
            {
                enum Impl = true;
            }
            else
            {
                alias Impl = Impl!(T[1 .. $]);
            }
        }
    }
    template Overloads(P...)
    {
        static if (P.length == 0)
        {
            enum Overloads = false;
        }
        else static if (hasUDA!(P[0], attribute))
        {
            enum Overloads = true;
        }
        else
        {
            alias Overloads = Overloads!(P[1 .. $]);
        }
    }

    alias HasMembersWithUDA = Impl!(__traits(derivedMembers, ClassName));
}

/**
Returns a string full of the structs for ClassName.
 */
template ConstraintStructs(ClassName, string ClusteredIndexAttributeName)
{
    string ConstraintStructs()
    {
        string result = "public:\n";
        foreach(name; UniqueConstraintStructNames!(ClassName))
        {
            static if (name == ClusteredIndexAttributeName)
            {
                result ~= "    final alias " ~ name ~ " = ClusteredIndex;\n";
                result ~= "    final alias " ~ name ~ "_key = key;\n";
            }
            else
            {
                result ~= "    final struct " ~ name ~ "\n";
                result ~= "    {\n";
                foreach(columnName; GetMembersWithUDA!(ClassName, UniqueConstraintColumn!name))
                {
                    result ~= "        typeof(" ~ ClassName.stringof ~ "." ~ columnName ~ ") " ~ columnName ~ ";\n";
                }
                result ~= "        mixin generic_compare!(" ~ name ~ ");\n";
                result ~= "    }\n";
                result ~= "    final @property " ~ name ~ " " ~ name ~ "_key() const nothrow pure @safe @nogc\n";
                result ~= "    {\n";
                result ~= "        auto _" ~ name ~ "_key = " ~ name ~ "();\n";
                foreach(columnName; GetMembersWithUDA!(ClassName, UniqueConstraintColumn!name))
                {
                    result ~= "        _" ~ name ~ "_key." ~ columnName ~ " = this._" ~ columnName ~ ";\n";
                }
                result ~= "        return _" ~ name ~ "_key;\n";
                result ~= "    }\n";
            }
        }
        return result;
    }
}
