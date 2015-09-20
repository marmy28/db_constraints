/**
User-defined attributes that can be used with the KeyedItem mixin.
 */
module db_constraints.constraints;

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


///
enum ForeignKeyActions
{
/**
When a parent key is modified or deleted from the collection, no special action is taken.
If you are using MySQL or MSSQL use `ForeignKeyActions.restrict` instead for the desired
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

/**
The foreign key user-defined attribute. Currently under :construction:
 */
struct ForeignKey(string name_, T)
    if (is(T == class))
{
    enum name = name_;
    ForeignKeyActions onUpdate = ForeignKeyActions.noAction;
    ForeignKeyActions onDelete = ForeignKeyActions.noAction;
    T parentType;
}

// mixin template ForeignKeyConstraint(ForeignClass, string ForeignClassConstraintName)
// {
//     void foreignKeyChanged(string propertyName, typeof(ForeignClass.key) item_key)
//     {
//         if (propertyName == ForeignClassConstraintName ~ "_key")
//         {
//             final switch (onUpdate)
//                 with (ForeignKeyActions)
//                 {
//                 case noAction:
//                     version(noActionIsRestrict)
//                     {
//                         goto case restrict;
//                     }
//                     else
//                     {
//                         // not doing anything
//                         break;
//                     }
//                 case restrict:
//                     if (_human.name != this._name_h)
//                     {
//                         throw new ForeignKeyException("ForeignKeyActions.restrict violation.");
//                     }
//                     break;
//                 case setNull:
//                     static if (__traits(compiles, this.name_h = null))
//                     {
//                         this.name_h = null;
//                         break;
//                     }
//                     else
//                     {
//                         throw new ForeignKeyException("Cannot use ForeignKeyActions.setNull " ~
//                                                       "when the member cannot be set to null.");
//                     }
//                 case setDefault:
//                     // somehow get the default if one is set...
//                     this.name_h = typeof(this.name_h).init;
//                     break;
//                 case cascade:
//                     this.name_h = _human.name;
//                     break;
//                 }
//         }
//     }
// }
