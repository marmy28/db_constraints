/**
The meta module contains:
  $(TOC opAAKey)
  $(TOC GetUniqueConstraintStructNames)
  $(TOC GetMembersWithUDA)
  $(TOC hasMembersWithUDA)
  $(TOC createConstraintStructs)
  $(TOC GetForeignKeys)
  $(TOC hasForeignKeys)
  $(TOC GetForeignKeyRefTable)
  $(TOC GetDefault)
  $(TOC hasDefault)
  $(TOC createForeignKeyPropertyConverter)
  $(TOC createForeignKeyProperties)
  $(TOC createForeignKeyCheckExceptions)
  $(TOC createForeignKeyChanged)
  $(TOC hasExclusionConstraints)
  $(TOC GetExclusionConstraints)

License: $(GPL2)

Authors: Matthew Armbruster

$(B Source:) $(SRC $(SRCFILENAME))

Copyright: 2016
 */
module db_constraints.utils.meta;

import std.meta : NoDuplicates, AliasSeq;
import std.traits : isInstanceOf, hasUDA;

import db_constraints.constraints;
/**
Used in KeyedItem for the generated structs.
This allows the struct to be used as a key
in an associative array.

The template loops over the members to define
toHash, opEquals, and opCmp for the struct.
 */
mixin template opAAKey(T)
    if (is(T == struct))
{
    // Gets the hash code of the struct by looping over the members.
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
    // Checks each member to determine if the structs are equal.
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
    // Compares each member and returns the result.
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
Gets the names given to the different UniqueConstraints for ClassName.
The UniqueConstraintColumns are usually put on getters and setters.
Returns:
    AliasSeq of all the distinct UniqueConstraintColumn.name in ClassName
 */
template GetUniqueConstraintStructNames(ClassName)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            alias Impl = AliasSeq!();
        }
        else
        {
            static if (__traits(compiles, __traits(getMember, ClassName, T[0])))
            {
                alias Impl = AliasSeq!(Overloads!(__traits(getOverloads, ClassName, T[0])), Impl!(T[1 .. $]));
            }
            else
            {
                alias Impl = AliasSeq!(Impl!(T[1 .. $]));
            }
        }
    }
    template Overloads(S...)
    {
        static if (S.length == 0)
        {
            alias Overloads = AliasSeq!();
        }
        else
        {
            enum attributes = Get!(__traits(getAttributes, S[0]));
            static if (attributes == "")
            {
                alias Overloads = AliasSeq!(Overloads!(S[1 .. $]));
            }
            else
            {
                alias Overloads = AliasSeq!(attributes, Overloads!(S[1 .. $]));
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
    alias GetUniqueConstraintStructNames = NoDuplicates!(Impl!(__traits(derivedMembers, ClassName)));
}

/**
Gets the properties of ClassName marked with @attribute. If the
attribute is PrimaryKeyColumn then it also confirms the property has
NotNull.
Returns:
    AliasSeq with distinct properties that have @attribute assigned to it.
 */
template GetMembersWithUDA(ClassName, attribute)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            alias Impl = AliasSeq!();
        }
        else
        {
            static if (__traits(compiles, __traits(getMember, ClassName, T[0])) &&
                       Overloads!(__traits(getOverloads, ClassName, T[0])))
            {
                alias Impl = AliasSeq!(T[0], Impl!(T[1 .. $]));
            }
            else
            {
                alias Impl = AliasSeq!(Impl!(T[1 .. $]));
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

/**
Confirms there are members in ClassName with @attribute.
Returns:
    true if there are members that have @attribute
 */
template hasMembersWithUDA(ClassName, attribute)
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

    enum hasMembersWithUDA = Impl!(__traits(derivedMembers, ClassName));
}

/*
Using the ClassName and ClusteredIndexAttributeName, createConstraintStructs will
append together strings using $(SRCTAG GetUniqueConstraintStructNames) and $(SRCTAG GetMembersWithUDA)
that make up the structs used as your unique keys.
Returns:
    A string full of the structs for ClassName that make each row unique.
 */
template createConstraintStructs(ClassName, string ClusteredIndexAttributeName)
{
    string createConstraintStructs()
    {
        string result = "public:\n";
        foreach(name; GetUniqueConstraintStructNames!(ClassName))
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
                    result ~= "        typeof(" ~ ClassName.stringof ~ "._" ~ columnName ~ ") " ~ columnName ~ ";\n";
                }
                result ~= "        mixin opAAKey!(" ~ name ~ ");\n";
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

/**
Gets all of the $(WIKI constraints, ForeignKey) that ClassName is attributed with. If
the foreign key name is left blank then the default name is $(D "fk_" ~ ClassName ~ "__" ~ referencedClassName).
 */
template GetForeignKeys(ClassName)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            alias Impl = AliasSeq!();
        }
        else static if (isInstanceOf!(ForeignKey, T[0]))
        {
            static if (T[0].name == "")
            {
                enum name = "fk_" ~ ClassName.stringof ~ "_" ~ T[0].referencedTableName;
                alias R = ForeignKey!(name, T[0].columnNames, T[0].referencedTableName, T[0].referencedColumnNames, T[0].updateRule, T[0].deleteRule);
                alias Impl = AliasSeq!(R, Impl!(T[1 .. $]));
            }
            else
            {
                alias Impl = AliasSeq!(T[0], Impl!(T[1 .. $]));
            }
        }
        else
        {
            alias Impl = Impl!(T[1 .. $]);
        }
    }
    alias GetForeignKeys = Impl!(__traits(getAttributes, ClassName));
}

/**
Confirms ClassName has foreign keys.
Returns:
    true if ClassName has an instance of @ForeignKey
 */
template hasForeignKeys(ClassName)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            enum Impl = false;
        }
        else static if (isInstanceOf!(ForeignKey, T[0]))
        {
            enum Impl = true;
        }
        else
        {
            alias Impl = Impl!(T[1 .. $]);
        }
    }
    enum hasForeignKeys = Impl!(__traits(getAttributes, ClassName));
}

/**
Gets all of the referenced foreign keys for ClassName.
Returns:
   Distinct list of all referenced classes for ClassName.
 */
template GetForeignKeyRefTable(ClassName)
    if (hasForeignKeys!(ClassName))
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            alias Impl = AliasSeq!();
        }
        else static if (isInstanceOf!(ForeignKey, T[0]))
        {
            enum attributes = T[0].referencedTableName;
            alias Impl = AliasSeq!(attributes, Impl!(T[1 .. $]));
        }
        else
        {
            alias Impl = Impl!(T[1 .. $]);
        }
    }
    alias GetForeignKeyRefTable = NoDuplicates!(Impl!(__traits(getAttributes, ClassName)));
}

/**
Gets the value for ClassName.memberName inside of @Default!(value) if memberName has @Default!(value)
 */
template GetDefault(ClassName, string memberName)
    if (hasDefault!(ClassName, memberName))
{
    static if (__traits(compiles, __traits(getMember, ClassName, memberName)))
    {
        alias GetDefault = Overloads!(__traits(getOverloads, ClassName, memberName));
    }
    else
    {
        alias GetDefault = AliasSeq!();
    }
    template Overloads(S...)
    {
        import std.conv : to;
        static if (S.length == 0)
        {
            alias Overloads = AliasSeq!();
        }
        else
        {
            enum attributes = Get!(__traits(getAttributes, S[0]));
            static if (attributes.to!string == "")
            {
                alias Overloads = Overloads!(S[1 .. $]);
            }
            else
            {
                alias Overloads = attributes;
            }
        }
    }
    template Get(P...)
    {
        static if (P.length == 0)
        {
            enum string Get = "";
        }
        else static if (isInstanceOf!(Default, P[0]))
        {
            enum Get = P[0].value;
        }
        else
        {
            alias Get = Get!(P[1 .. $]);
        }
    }
}

/**
Confirms ClassName.memberName has @Default!(value)
Returns:
    true if ClassName.memberName has @Default!(value)
 */
template hasDefault(ClassName, string memberName)
{
    static if (__traits(compiles, __traits(getMember, ClassName, memberName)))
    {
        enum hasDefault = Overloads!(__traits(getOverloads, ClassName, memberName));
    }
    else
    {
        enum hasDefault = false;
    }
    template Overloads(S...)
    {
        static if (S.length == 0)
        {
            enum Overloads = false;
        }
        else
        {
            enum attributes = Get!(__traits(getAttributes, S[0]));
            static if (attributes)
            {
                enum Overloads = true;
            }
            else
            {
                alias Overloads = Overloads!(S[1 .. $]);
            }
        }
    }
    template Get(P...)
    {
        static if (P.length == 0)
        {
            enum Get = false;
        }
        else static if (isInstanceOf!(Default, P[0]))
        {
            enum Get = true;
        }
        else
        {
            alias Get = Get!(P[1 .. $]);
        }
    }
}
/**
Creates the foreign key properties inside of $(D KeyedItem)
that convert the keyed items properties into the necessary
foreign key clustered index.
 */
template createForeignKeyPropertyConverter(ClassName)
{
    string createForeignKeyPropertyConverter()
    {
        string result = "";
        foreach(foreignKey; GetForeignKeys!(ClassName))
        {
            result ~= "final bool " ~ foreignKey.name ~ "_key(out " ~ foreignKey.referencedTableName ~ ".key_type aKey)\n";
            result ~= "{\n";
            result ~= "    bool result;\n";
            result ~= "    static if (\n";
            for (int i = 0; i < foreignKey.columnNames.length; ++i)
            {
                if (i > 0)
                {
                    result ~= " &&\n";
                }
                result ~= "        is(typeof(aKey." ~ foreignKey.referencedColumnNames[i] ~ ") == typeof(this." ~ foreignKey.columnNames[i] ~ "))";
            }
            result ~= "\n";
            result ~= "        )\n";
            result ~= "    {\n";
            for (int i = 0; i < foreignKey.columnNames.length; ++i)
            {
                result ~= "        aKey." ~ foreignKey.referencedColumnNames[i] ~ " = this." ~ foreignKey.columnNames[i] ~ ";\n";
            }
            result ~= "        result = true;\n";
            result ~= "    }\n";
            result ~= "    else static if (__traits(compiles,\n";
            result ~= "                             (" ~ ClassName.stringof ~ " b)\n";
            result ~= "                             {\n";
            foreach(columnName; foreignKey.columnNames)
            {
                result ~= "                                 if (b." ~ columnName ~ ".isNull == true) { }\n";
            }
            result ~= "                             }))\n";
            result ~= "    {\n";
            result ~= "        if (\n";
            foreach(columnName; foreignKey.columnNames)
            {
                if (columnName != foreignKey.columnNames[0])
                {
                    result ~= " &&\n";
                }
                result ~= "            !this." ~ columnName ~ ".isNull";
            }
            result ~= "\n";
            result ~= "           )\n";
            result ~= "        {\n";
            for (int i = 0; i < foreignKey.columnNames.length; ++i)
            {
                result ~= "            aKey." ~ foreignKey.referencedColumnNames[i] ~ " = this." ~ foreignKey.columnNames[i] ~ ";\n";
            }
            result ~= "            result = true;\n";
            result ~= "        }\n";
            result ~= "        else\n";
            result ~= "        {\n";
            result ~= "            result = false;\n";
            result ~= "        }\n";
            result ~= "    }\n";
            result ~= "    else\n";
            result ~= "    {\n";
            result ~= "        static assert(false, \"Column type mismatch for "~ foreignKey.name ~ ".\");\n";
            result ~= "    }\n";
            result ~= "    return result;\n";
            result ~= "}\n";
        }
        return result;
    }
}

/**
Creates the foreign key properties that will be used in KeyedCollection.
It loops over all of the foreign key attributes for ClassName and creates
a write-only property for each referenced class by using the class' name
in lower case. There is a static assert that makes sure the lower case
class name does not equal the class name. This would result in name
collisions and is not conforming to the D style.

There are two setters that are made. One takes the referenced class
by reference and the other accepts null. The null setter removes the
reference and disconnects the emitted signals. The setter that takes
the class by reference connects the emitted signals and keeps the
address of the class to check foreign key constraints when anything
changes.
 */
template createForeignKeyProperties(ClassName)
{
    string createForeignKeyProperties()
    {
        import std.uni : toLower;
        string result = "";
        foreach(member; GetForeignKeyRefTable!(ClassName))
        {
            static assert(member != member.toLower, "The class " ~ member ~ " should start with a capital letter to use Foreign Keys or else there will be name collisions.");
            result ~= "private " ~ member ~ " *_" ~ member.toLower ~ ";\n";
            result ~= "private " ~ member ~ ".key_type _changed" ~ member ~ "Row;\n";

            result ~= "final @property void " ~ member.toLower ~ "(ref " ~ member ~ " " ~ member.toLower ~ "_)\n";
            result ~= "{\n";
            result ~= "    this." ~ member.toLower ~ " = null;\n";
            result ~= "    this._" ~ member.toLower ~ " = &" ~ member.toLower ~ "_;\n";
            foreach(foreignKey; GetForeignKeys!(ClassName))
            {
                static if (foreignKey.referencedTableName == member)
                {
                    result ~= "    this._" ~ member.toLower ~ ".collectionChanged.connect(&" ~ foreignKey.name ~ "_Changed);\n";
                }
            }
            result ~= "    checkForeignKeys();\n";
            result ~= "}\n";


            result ~= "final @property void " ~ member.toLower ~ "(typeof(null) n)\n";
            result ~= "{\n";
            result ~= "    if (this._" ~ member.toLower ~ " !is null)\n";
            result ~= "    {\n";
            foreach(foreignKey; GetForeignKeys!(ClassName))
            {
                static if (foreignKey.referencedTableName == member)
                {
                    result ~= "        this._" ~ member.toLower ~ ".collectionChanged.disconnect(&" ~ foreignKey.name ~ "_Changed);\n";
                }
            }
            result ~= "    this._" ~ member.toLower ~ " = null;\n";
            result ~= "    }\n";
            result ~= "}\n";
        }
        return result;
    }
}

/**
Creates the foreign key check exceptions by seeing if the foreign key has been associated and
whether or not the referenced table has a matching record.
 */
template createForeignKeyCheckExceptions(ClassName)
{
    string createForeignKeyCheckExceptions()
    {
        import std.uni : toLower;
        string result = "";
        foreach(foreignKey; GetForeignKeys!(ClassName))
        {
            static assert(foreignKey.referencedTableName != foreignKey.referencedTableName.toLower, "The class " ~ member ~ " should start with a capital letter to use Foreign Keys or else there will be name collisions.");
            result ~= "if (this._" ~ foreignKey.referencedTableName.toLower ~ " !is null)\n";
            result ~= "{\n";
            result ~= "    " ~ foreignKey.referencedTableName ~ ".key_type i;\n";
            result ~= "    if(a." ~ foreignKey.name ~ "_key(i))\n";
            result ~= "    {\n";
            result ~= "        enforceEx!ForeignKeyException(this._" ~ foreignKey.referencedTableName.toLower ~ ".contains(i), \"" ~ foreignKey.name ~ " violation.\");\n";
            result ~= "    }\n";
            result ~= "}\n";
        }
        return result;
    }
}

/**
Creates the foreign keys update rule and delete rule property and sets them to the foreign key attribute property.
It also creates the function that will be attached to the foreign key when it is associated. This is where
the update rule and delete rule are used since the referenced class will emit what changed and to which item.
 */
template createForeignKeyChanged(ClassName)
{
    string createForeignKeyChanged()
    {
        import std.conv : to;
        string result = "";
        foreach(foreignKey; GetForeignKeys!(ClassName))
        {
            result ~= "Rule " ~ foreignKey.name ~ "_UpdateRule = Rule." ~ foreignKey.updateRule.to!string ~ ";\n";
            result ~= "Rule " ~ foreignKey.name ~ "_DeleteRule = Rule." ~ foreignKey.deleteRule.to!string ~ ";\n";
            result ~= "void " ~ foreignKey.name ~ "_Changed(string propertyName, " ~ foreignKey.referencedTableName ~ ".key_type item_key)\n";
            result ~= "{\n";
            result ~= "    if (canFind(" ~ foreignKey.referencedColumnNames.to!string ~ ", propertyName))\n";
            result ~= "    {\n";
            result ~= "        this._changed" ~ foreignKey.referencedTableName ~ "Row = item_key;\n";
            result ~= "    }\n";
            result ~= "    else if (propertyName == \"key\")\n";
            result ~= "    {\n";
            // onUpdate
            result ~= "        auto changed" ~ foreignKey.referencedTableName ~ " = this.byValue.filter!(\n";
            result ~= "            (" ~ ClassName.stringof ~ " a) =>\n";
            result ~= "            {\n";
            result ~= "                " ~ foreignKey.referencedTableName ~ ".key_type i;\n";
            result ~= "                return (a." ~ foreignKey.name ~ "_key(i) ? i == this._changed" ~ foreignKey.referencedTableName ~ "Row : false);\n";
            result ~= "            }());\n";
            result ~= "        final switch (" ~ foreignKey.name ~ "_UpdateRule) with (Rule)\n";
            result ~= "        {\n";
            result ~= "        case noAction:\n";
            result ~= "            break;\n";
            result ~= "        case restrict:\n";
            result ~= "            if (!changed" ~ foreignKey.referencedTableName ~ ".empty)\n";
            result ~= "                throw new ForeignKeyException(\"" ~ foreignKey.name ~ " violation.\");\n";
            result ~= "            break;\n";
            result ~= "        case setNull:\n";
            result ~= "        static if (__traits(compiles,\n";
            result ~= "                            (" ~ ClassName.stringof ~ " a)\n";
            result ~= "                            {\n";
            foreach(columnName; foreignKey.columnNames)
            {
                result ~= "                                a." ~ columnName ~ " = null;\n";
            }
            result ~= "                            }))\n";
            result ~= "            {\n";
            result ~= "                changed" ~ foreignKey.referencedTableName ~ ".each!(\n";
            result ~= "                    (" ~ ClassName.stringof ~ " a) =>\n";
            result ~= "                    {\n";
            foreach(columnName; foreignKey.columnNames)
            {
                result ~= "                        a." ~ columnName ~ " = null;\n";
            }
            result ~= "                    }());\n";
            result ~= "                break;\n";
            result ~= "            }\n";
            result ~= "            else\n";
            result ~= "            {\n";
            result ~= "                throw new ForeignKeyException(\"" ~ foreignKey.name ~ ". Cannot use Rule.setNull when the member cannot be set to null.\");\n";
            result ~= "            }\n";
            result ~= "        case setDefault:\n";
            result ~= "            changed" ~ foreignKey.referencedTableName ~ ".each!(\n";
            result ~= "                (" ~ ClassName.stringof ~ " a) =>\n";
            result ~= "                {\n";
            foreach(columnName; foreignKey.columnNames)
            {
                result ~= "                    static if (hasDefault!(" ~ ClassName.stringof ~ ", \"" ~ columnName ~ "\"))";
                result ~= "                    {\n";
                result ~= "                        a." ~ columnName ~ " = GetDefault!(" ~ ClassName.stringof ~ ", \"" ~ columnName ~ "\");\n";
                result ~= "                    }\n";
                result ~= "                    else\n";
                result ~= "                    {\n";
                result ~= "                        a." ~ columnName ~ " = typeof(a." ~ columnName ~ ").init;\n";
                result ~= "                    }\n";
            }
            result ~= "                }());\n";
            result ~= "            break;\n";
            result ~= "        case cascade:\n";
            result ~= "            changed" ~ foreignKey.referencedTableName ~ ".each!(\n";
            result ~= "                (" ~ ClassName.stringof ~ " a) =>\n";
            result ~= "                {\n";
            for (int i = 0; i < foreignKey.columnNames.length; ++i)
            {
                result ~= "                    a." ~ foreignKey.columnNames[i] ~ " = item_key." ~ foreignKey.referencedColumnNames[i] ~ ";\n";
            }
            result ~= "                }());\n";
            result ~= "            break;\n";

            result ~= "        }\n";
            result ~= "    }\n";
            result ~= "    else if (propertyName == \"remove\")\n";
            result ~= "    {\n";
            // onDelete
            result ~= "        auto removed" ~ foreignKey.referencedTableName ~ " = this.byValue.filter!(\n";
            result ~= "            (" ~ ClassName.stringof ~ " a) =>\n";
            result ~= "            {\n";
            result ~= "                " ~ foreignKey.referencedTableName ~ ".key_type i;\n";
            result ~= "                return (a." ~ foreignKey.name ~ "_key(i) ? i == item_key : false);\n";
            result ~= "            }());\n";
            result ~= "        final switch (" ~ foreignKey.name ~ "_DeleteRule) with (Rule)\n";
            result ~= "        {\n";
            result ~= "        case noAction:\n";
            result ~= "            break;\n";
            result ~= "        case restrict:\n";
            result ~= "            if (!removed" ~ foreignKey.referencedTableName ~ ".empty)\n";
            result ~= "                throw new ForeignKeyException(\"" ~ foreignKey.name ~ " violation.\");\n";
            result ~= "            break;\n";
            result ~= "        case setNull:\n";
            result ~= "        static if (__traits(compiles,\n";
            result ~= "                            (" ~ ClassName.stringof ~ " a)\n";
            result ~= "                            {\n";
            foreach(columnName; foreignKey.columnNames)
            {
                result ~= "                                a." ~ columnName ~ " = null;\n";
            }
            result ~= "                            }))\n";
            result ~= "            {\n";
            result ~= "                removed" ~ foreignKey.referencedTableName ~ ".each!(\n";
            result ~= "                    (" ~ ClassName.stringof ~ " a) =>\n";
            result ~= "                    {\n";
            foreach(columnName; foreignKey.columnNames)
            {
                result ~= "                        a." ~ columnName ~ " = null;\n";
            }
            result ~= "                    }());\n";
            result ~= "                break;\n";
            result ~= "            }\n";
            result ~= "            else\n";
            result ~= "            {\n";
            result ~= "                throw new ForeignKeyException(\"" ~ foreignKey.name ~ ". Cannot use Rule.setNull when the member cannot be set to null.\");\n";
            result ~= "            }\n";
            result ~= "        case setDefault:\n";
            result ~= "            removed" ~ foreignKey.referencedTableName ~ ".each!(\n";
            result ~= "                (" ~ ClassName.stringof ~ " a) =>\n";
            result ~= "                {\n";
            foreach(columnName; foreignKey.columnNames)
            {
                result ~= "                    static if (hasDefault!(" ~ ClassName.stringof ~ ", \"" ~ columnName ~ "\"))";
                result ~= "                    {\n";
                result ~= "                        a." ~ columnName ~ " = GetDefault!(" ~ ClassName.stringof ~ ", \"" ~ columnName ~ "\");\n";
                result ~= "                    }\n";
                result ~= "                    else\n";
                result ~= "                    {\n";
                result ~= "                        a." ~ columnName ~ " = typeof(a." ~ columnName ~ ").init;\n";
                result ~= "                    }\n";
            }
            result ~= "                }());\n";
            result ~= "            break;\n";

            result ~= "        case cascade:\n";
            result ~= "            removed" ~ foreignKey.referencedTableName ~ ".each!(\n";
            result ~= "                (" ~ ClassName.stringof ~ " a) =>\n";
            result ~= "                {\n";
            result ~= "                    this.remove(a.key);\n";
            result ~= "                }());\n";
            result ~= "            break;\n";
            result ~= "        }\n";
            result ~= "    }\n";
            result ~= "}\n";
        }
        return result;
    }
}

/**
Confirms ClassName has exclusion constraints.
Returns:
    true if ClassName has an instance of @ExclusionConstraint
 */
template hasExclusionConstraints(ClassName)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            enum Impl = false;
        }
        else static if (isInstanceOf!(ExclusionConstraint, T[0]))
        {
            enum Impl = true;
        }
        else
        {
            alias Impl = Impl!(T[1 .. $]);
        }
    }
    enum hasExclusionConstraints = Impl!(__traits(getAttributes, ClassName));
}

/**
Gets all of the $(WIKI constraints, ExclusionConstraint) that ClassName is attributed with. If
the exclusion constraint name is left blank then the default name is $(D "exc_" ~ ClassName).
 */
template GetExclusionConstraints(ClassName)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            alias Impl = AliasSeq!();
        }
        else static if (isInstanceOf!(ExclusionConstraint, T[0]))
        {
            static if (T[0].name == "")
            {
                enum name = "exc_" ~ ClassName.stringof;
                alias R = ExclusionConstraint!(T[0].exclusion, name);
                alias Impl = AliasSeq!(R, Impl!(T[1 .. $]));
            }
            else
            {
                alias Impl = AliasSeq!(T[0], Impl!(T[1 .. $]));
            }
        }
        else
        {
            alias Impl = Impl!(T[1 .. $]);
        }
    }
    alias GetExclusionConstraints = Impl!(__traits(getAttributes, ClassName));
}
