/**
User-defined attributes that can be used with the KeyedItem mixin.
The constraints module contains:
  $(TOC UniqueConstraintColumn)
  $(TOC PrimaryKeyColumn)
  $(TOC ExclusionConstraint)
  $(TOC CheckConstraint)
  $(TOC NotNull)
  $(TOC SetConstraint)
  $(TOC EnumConstraint)
  $(TOC Rule)
  $(TOC ForeignKey)
  $(TOC ForeignKeyConstraint)
  $(TOC Default)

License: $(GPL2)

Authors: Matthew Armbruster

$(B Source:) $(SRC $(SRCFILENAME))
Copyright: 2015
 */
module db_constraints.constraints;

import std.functional : binaryFun, unaryFun;

/**
KeyedItem will create a struct with $(I name) defined in the compile-time
argument. For example a property marked with @UniqueColumn!("uc_Person") will
be part of the struct uc_Person.
Params:
    name_ = The name of the constraint which is the structs name
 */
struct UniqueConstraintColumn(string name_)
{
    enum name = name_;
}

/**
An alias for the primary key column. A member with this attribute
must also have the NotNull attribute.
 */
alias PrimaryKeyColumn = UniqueConstraintColumn!("PrimaryKey");

/**
Mimics Postgresql's Exclude Constraint. This will exclude any
items that return true to the $(D exclusion_).

Version: \>= 0.0.7
 */
struct ExclusionConstraint(alias exclusion_, string name_ = "")
    if (is(typeof(binaryFun!exclusion_)))
{
    alias exclusion = binaryFun!exclusion_;
    enum name = name_;
}

/**
$(WIKI keyeditem, KeyedItem.checkConstraints) will check all of the members
marked with this attribute and use the check given.

Version: \>= 0.0.6 allows you to mark your class as well.

Params:
    check_ = The function that returns a boolean
    name_ = Name used in the error message if the function returns false
 */
struct CheckConstraint(alias check_, string name_ = "")
    if (is(typeof(unaryFun!check_)))
{
    alias check = unaryFun!check_;
    enum name = name_;
}

/**
Alias for a special check constraint that makes sure the column is never null.
This is checked the same time as all the other check constraints. The name of
the constraint is NotNull in the error messages if this is ever violated.
 */
alias NotNull = CheckConstraint!(
    function bool(auto ref a)
    {
        static if (__traits(hasMember, typeof(a), "isNull"))
        {
            return !a.isNull;
        }
        else static if (__traits(compiles, typeof(a).init == null))
        {
            return a !is null;
        }
        else
        {
            return true;
        }
    }, "NotNull");

import std.traits : isExpressions;
/**
Alias for check constraint that makes sure the property that
has this attribute only contains members in the set. This should
act like the SET constraint in MySQL. It will sort and remove the
duplicates of the SET. This does modify the value coming in. This
is only for strings.

If $(D isStrict) is true, SetConstraint will return false if
you include a value not in the set. If $(D isStrict) is
false, the value will be set to an empty string.

Version: \>= 0.0.6 for $(D isStrict) option.
\>= 0.0.4 is always strict.
 */
template SetConstraint(values...)
    if (isExpressions!values)
{
    alias SetConstraint = SetConstraint!(true, values);
}
/// ditto
template SetConstraint(bool isStrict, values...)
    if (isExpressions!values)
{
    alias SetConstraint = CheckConstraint!(
        function bool(auto ref a)
        {
            static assert(is(typeof(a) == string));

            if (a !is null)
            {
                import std.array : split;
                import std.algorithm : among, aSort = sort, uniq;
                auto options = a.split(",").aSort.uniq;
                a = "";
                foreach(string option; options)
                {
                    if (!option.among!(values))
                    {
                        static if (isStrict)
                        {
                            return false;
                        }
                        else
                        {
                            continue;
                        }
                    }
                    if (a != "")
                    {
                        a ~= ",";
                    }
                    a ~= option;
                }
            }
            return true;
        }, "Set");
}

/**
Alias for check constraint that makes sure the property that
has this attribute only contains a member that is part of the
enumeration. This should act like the ENUM constraint in MySQL.
This does modify the value coming in. This is only for strings.

If $(D isStrict) is true, EnumConstraint will return false if
you include a value not in the enumeration. If $(D isStrict) is
false, the value will be set to an empty string.

Version: \>= 0.0.6
 */
template EnumConstraint(values...)
    if (isExpressions!values)
{
    alias EnumConstraint = EnumConstraint!(true, values);
}
/// ditto
template EnumConstraint(bool isStrict, values...)
    if (isExpressions!values)
{
    alias EnumConstraint = CheckConstraint!(
        function bool(auto ref a)
        {
            import std.algorithm : among;
            static assert(is(typeof(a) == string));

            if (a !is null)
            {
                static if (isStrict)
                {
                    return a.among!(values);
                }
                else
                {
                    if (!a.among!(values))
                    {
                        a = "";
                    }
                }
            }
            return true;
        }, "Enum");
}

/**
Rules for foreign keys when updating or deleting.
 */
enum Rule
{
/**
When a parent key is modified or deleted from the collection, no special
action is taken. If you are using MySQL or MSSQL use
$(SRCTAG Rule.restrict) instead for the desired effect.
 */
    noAction,
/**
The item is prohibited from deleting or modifying a parent key when there exists
one or more child keys mapped to it. This is the default.

$(THROWS ForeignKeyException, when a member changes.)
 */
    restrict,
/**
Sets the member to $(D null) when deleting or modifying a parent key.

$(THROWS ForeignKeyException, when the type cannot be set to null.)
 */
    setNull,
/**
Sets the member to the Default value when deleting or modifying a parent key.
If there is no defined Default then the member is set to its types initial
value.
 */
    setDefault,
/**
Updates or deletes the item based on what happened to the parent key.
 */
    cascade
}

/**
$(SRCTAG ForeignKeyConstraint) should be used instead of this struct.
This is more the behind the scenes struct.
Params:
    name_ = The name of the foreign key constraint. Will be used in error message when violated
    columnNames_ = The members in the child class that are used in the foreign key
    referencedTableName_ = The referenced table's name (collection class)
    referencedColumnNames_ = The members in the parent class that are references in the foreign key
    updateRule_ = Rule when a foreign key is updated that is being referenced
    deleteRule_ = Rule when a foreign key is deleted that is being referenced
 */
struct ForeignKey(string name_,
                  string[] columnNames_,
                  string referencedTableName_,
                  string[] referencedColumnNames_,
                  Rule updateRule_,
                  Rule deleteRule_)
{
    enum string name = name_;
    enum string[] columnNames = columnNames_;
    enum string referencedTableName = referencedTableName_;
    enum string[] referencedColumnNames = referencedColumnNames_;
    enum Rule updateRule = updateRule_;
    enum Rule deleteRule = deleteRule_;
}

/**
The foreign key user-defined attribute.
 */
template ForeignKeyConstraint(string name_, string[] columnNames_,
                              string referencedTableName_,
                              string[] referencedColumnNames_,
                              Rule updateRule_, Rule deleteRule_)
{
    alias ForeignKeyConstraint = ForeignKey!(name_, columnNames_,
                                             referencedTableName_,
                                             referencedColumnNames_,
                                             updateRule_, deleteRule_);
}

/// ditto
template ForeignKeyConstraint(string name_, string[] columnNames_,
                              string referencedTableName_,
                              string[] referencedColumnNames_)
{
    alias ForeignKeyConstraint = ForeignKey!(name_, columnNames_,
                                             referencedTableName_,
                                             referencedColumnNames_,
                                             Rule.restrict, Rule.restrict);
}

/// ditto
template ForeignKeyConstraint(string[] columnNames_,
                              string referencedTableName_,
                              string[] referencedColumnNames_,
                              Rule updateRule_, Rule deleteRule_)
{
    alias ForeignKeyConstraint = ForeignKey!("", columnNames_,
                                             referencedTableName_,
                                             referencedColumnNames_,
                                             updateRule_, deleteRule_);
}

/// ditto
template ForeignKeyConstraint(string[] columnNames_,
                              string referencedTableName_,
                              string[] referencedColumnNames_)
{
    alias ForeignKeyConstraint = ForeignKey!("", columnNames_,
                                             referencedTableName_,
                                             referencedColumnNames_,
                                             Rule.restrict, Rule.restrict);
}

/**
Default used with $(SRCTAG Rule.setDefault) for foreign keys.
Params:
    value_ = the value that should be used for the default value.
 */
struct Default(alias value_)
{
    enum value = value_;
}


