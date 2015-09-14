module db_extensions.extra.constraints;

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

// @ForeignKey{Area.nAreaID, Cascade on delete, cascade on update}
enum ForeignKeyActions
{
    noAction,
    restrict,
    setNull,
    setDefault,
    cascade
}
struct ForeignKey(string name_, T)
    if (is(T == class))
{
    enum name = name_;
    ForeignKeyActions onUpdate = ForeignKeyActions.noAction;
    ForeignKeyActions onDelete = ForeignKeyActions.noAction;
    T parentType;
}

// MySQL && MSSQL treats noAction like restrict
version(MySQL)
{
    version = noActionIsRestrict;
}
else version(MSSQL)
{
    version = noActionIsRestrict;
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
