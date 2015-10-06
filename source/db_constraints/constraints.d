/**
 * User-defined attributes that can be used with the KeyedItem mixin.
 *
 * Copyright: 2015
 * License: GNU GENERAL PUBLIC LICENSE Version 2
 * Authors: Matthew Armbruster
 */
module db_constraints.constraints;

import std.functional : unaryFun;

/**
KeyedItem will create a struct with *name* defined in the compile-time argument.
For example a property marked with @UniqueColumn!("uc_Person") will
be part of the struct uc_Person.
Params:
    name_ = The name of the constraint which is the structs name.
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
KeyedItem.checkConstraints will check all of the members marked
with this attribute and use the check given.
Params:
    check_ = The function that returns a boolean.
    name_ = Name used in the error message if the function returns false.
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
    function bool(auto a)
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

///
enum Rule
{
/**
When a parent key is modified or deleted from the collection, no special action is taken.
If you are using MySQL or MSSQL use `Rule.restrict` instead for the desired
effect.
 */
    noAction,
/**
The item is prohibited from deleting or modifying a parent key when there exists
one or more child keys mapped to it.
Throws:
    ForeignKeyException when a member changes.
 */
    restrict,
/**
Sets the member to `null` when deleting or modifying a parent key.
Throws:
    ForeignKeyException when the type cannot be set to null.
 */
    setNull,
/**
Sets the member to the types initial value when deleting or modifying a parent key.
Bugs:
   Currently can only set to the initial value.
 */
    setDefault,
/**
Updates or deletes the item based on what happened to the parent key.
 */
    cascade
}


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
The foreign key user-defined attribute. Currently under :construction:
Params:
    name_ = The name of the foreign key constraint. Will be used in error message when violated
    columnNames_ = The members in the child class that are used in the foreign key
    referencedTableName_ = The referenced table's name (collection class).
    referencedColumnNames_ = The members in the parent class that are references in the foreign key
    updateRule_ = What should happen when a foreign key is updated that is being referenced.
    deleteRule_ = What should happen when a foreign key is deleted that is being referenced.
 */
template ForeignKeyConstraint(string name_, string[] columnNames_, string referencedTableName_,
                              string[] referencedColumnNames_, Rule updateRule_, Rule deleteRule_)
{
    alias ForeignKeyConstraint = ForeignKey!(name_, columnNames_, referencedTableName_,
                                             referencedColumnNames_, updateRule_, deleteRule_);
}

/// ditto
template ForeignKeyConstraint(string name_, string[] columnNames_, string referencedTableName_,
                              string[] referencedColumnNames_)
{
    alias ForeignKeyConstraint = ForeignKey!(name_, columnNames_, referencedTableName_,
                                             referencedColumnNames_, Rule.noAction, Rule.noAction);
}

/// ditto
template ForeignKeyConstraint(string[] columnNames_, string referencedTableName_,
                              string[] referencedColumnNames_, Rule updateRule_, Rule deleteRule_)
{
    alias ForeignKeyConstraint = ForeignKey!("", columnNames_, referencedTableName_,
                                             referencedColumnNames_, updateRule_, deleteRule_);
}

/// ditto
template ForeignKeyConstraint(string[] columnNames_, string referencedTableName_,
                              string[] referencedColumnNames_)
{
    alias ForeignKeyConstraint = ForeignKey!("", columnNames_, referencedTableName_,
                                             referencedColumnNames_, Rule.noAction, Rule.noAction);
}

struct Default(alias value_)
{
    enum value = value_;
}
