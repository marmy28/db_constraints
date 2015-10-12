# Change log

## 0.0.4 (release date: 2015-10-12)

### Name changes

 * db_extensions -> db_constraints
   + the repo name was changed and all followed.
 * db_constraints.keyed.keyeditem.UniqueConstraintStructNames -> db_constraints.utils.generickey.UniqueConstraintStructNames
 * db_constraints.keyed.keyeditem.getColumns -> db_constraints.utils.generickey.GetMembersWithUDA
 * db_constraints.utils.generickey -> db_constraints.utils.meta
 * db_constraints.utils.meta.generic_compare -> db_constraints.utils.meta.opAAKey
 * db_constraints.utils.meta.ConstraintStructs -> db_constraints.utils.meta.createConstraintStructs

### New additions

 * NotNull attribute
 * db_constraints.utils.meta.hasMembersWithUDA
 * mixin template KeyedCollection
 * ForeignKeyConstraint
 * ForeignKey
 * struct Default(alias value_)
 * a lot of functions in utils.meta...
 * SetConstraint

### Misc.

 * UniqueConstraintColumn marked on overloaded functions are now recognized.
 * BaseKeyedCollection now emits the changed propertyName and the items key.
 * BaseKeyedCollection.violatesUniqueConstraints constraintName parameter is null if the constraint is not violated.
 * A member marked with PrimaryKeyColumn must also be marked with NotNull.
 * BaseKeyedCollection.opBinaryRight!("in") returns a pointer to the object (or null) instead of a boolean.
 * Unique constraint violations message now includes the class name that had the violation.
 * KeyedItem only takes ClusteredIndexAttribute now
 * KeyedCollection is a mixin while BaseKeyedCollection continues to be a class
 * Using Coveralls now!
 * Foreign Key Constraints are now enforced and can be set to null, default, restricted, no action, or cascading with updates and deletes
 * Nullable went back to looking more like Phobos with extra functionality.
 * enforceConstraints now takes a bitwise or arguement
 * github.ddoc is better than ever!

## 0.0.3 (release date: 2015-09-19)

### Name changes

 * isDuplicateItem -> violatesUniqueConstraints
 * enforceUniqueConstraints -> enforceConstraints

### New additions

 * struct CheckConstraint(alias check_, string name_ = "")
 * template KeyedItem.setter!(string name_ = \__FUNCTION__)
 * void KeyedItem.initializeKeyedItem()
 * void KeyedItem.checkConstraints()
 * void BaseKeyedCollection.checkConstraints()

### Misc.

 * enforces check constraints using a UDA with a lambda function!
 * marked functions as final for keyedcollection and keyeditem
 * to properly initialize the keyed item mixin you need to add initializeKeyedItem in your constructor
 * setClustedIndex is now called inside initializeKeyedItem
 * notify now takes the property name that changed as a compile time argument

### Bugs

 * UniqueConstraintColumn marked overloaded functions (getters and setters) might not be picked up

## 0.0.2 (release date: 2015-09-13)

### Name changes

 * UniqueColumn -> UniqueConstraintColumn
 * struct PrimaryKey -> struct ClusteredIndex
 * setPrimaryKey() -> setClusteredIndex()
 * PrimaryKeyColumn() -> PrimaryKeyColumn
 * PrimaryKeyException -> UniqueConstraintException

### New additions

 * BaseKeyedCollection.remove
 * BaseKeyedCollection.enforceUniqueConstraints
 * BaseKeyedCollection.isDuplicateItem
 * Github flavored markdown docs!
 * A change log was added

### Misc.

 * moved the UDA PrimaryKeyColumn from a struct to an alias
 * only one signal is emitted from the mixin template KeyedItem
 * better checks with contract programming
 * can now use the contents of the clustered index in BaseKeyedCollection for
   + contains
   + opBinaryRight!("in")
   + opIndex
   + remove
 * Unique constraint columns are now enforced and you can have more than 1!
 * The constraint checks can be turned on and off.
 * BaseKeyedCollection no longer has to have a PrimaryKey but instead just uses typeof(T.key)

## 0.0.1 (release date: 2015-08-23)

### Misc.

 * Initial tag
 * Has the ability to have primary keys
 * Uses primary key when comparing
 * Uses primary key as AA key
 * Checks for conflicting primary keys
 * Uses travis ci

### Bugs

 * Still in development so many functions are likely to change
 * The UniqueColumn attribute does nothing and you can only have one
