module db_extensions.extra.constraints;

import std.functional : unaryFun;

/**
User-defined attribute that can be used with KeyedItem. KeyedItem
will create a struct made up of all of the properties marked with
@PrimaryKeyColumn which can be used with KeyedCollection as
keys in an associative array by default.
 */
alias PrimaryKeyColumn = UniqueConstraintColumn!("PrimaryKey");
/**
User-defined attribute that can be used with KeyedItem. KeyedItem
will create a struct with name defined in the compile-time argument.
For example a property marked with @UniqueColumn!("uc_Person") will
be part of the struct uc_Person.
 */
struct UniqueConstraintColumn(string name_)
{
    /// The name of the constraint which is the structs name.
    enum name = name_;
}

struct CheckConstraint(alias check_)
    if (is(typeof(unaryFun!check_)))
{
    alias check = unaryFun!check_;
}
