# Change log

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