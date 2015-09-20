/**
User-defined attributes that can be used with the KeyedItem mixin.
 */
module db_constraints.extra.constraints;

import std.functional : unaryFun;

/**
KeyedItem will create a struct with *name* defined in the compile-time argument.
For example a property marked with @UniqueColumn!("uc_Person") will
be part of the struct uc_Person.
 */
struct UniqueConstraintColumn(string name_)
{
/**
The name of the constraint which is the structs name.
 */
    enum name = name_;
}

/**
An alias for the primary key column.
 */
alias PrimaryKeyColumn = UniqueConstraintColumn!("PrimaryKey");


/**
KeyedItem.checkConstraints will check all of the members marked
with this attribute and use the check given.
 */
struct CheckConstraint(alias check_, string name_ = "")
    if (is(typeof(unaryFun!check_)))
{
/**
The function that returns a boolean.
 */
    alias check = unaryFun!check_;
/**
Name used in the error message if the function returns false. This may
help narrow down which constraint failed.
 */
    enum name = name_;
}
