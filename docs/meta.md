# db_constraints.utils.meta


The meta module contains:
  + [opAAKey](#opAAKey)
  + [GetUniqueConstraintStructNames](#GetUniqueConstraintStructNames)
  + [GetMembersWithUDA](#GetMembersWithUDA)
  + [hasMembersWithUDA](#hasMembersWithUDA)
  + [createConstraintStructs](#createConstraintStructs)
  + [GetForeignKeys](#GetForeignKeys)
  + [hasForeignKeys](#hasForeignKeys)
  + [GetForeignKeyRefTable](#GetForeignKeyRefTable)
  + [GetDefault](#GetDefault)
  + [hasDefault](#hasDefault)
  + [createForeignKeyPropertyConverter](#createForeignKeyPropertyConverter)
  + [createForeignKeyProperties](#createForeignKeyProperties)
  + [createForeignKeyCheckExceptions](#createForeignKeyCheckExceptions)
  + [createForeignKeyChanged](#createForeignKeyChanged)
  + [hasExclusionConstraints](#hasExclusionConstraints)
  + [GetExclusionConstraints](#GetExclusionConstraints)

**License:**
[GPL-2.0](https://github.com/marmy28/db_constraints/blob/master/LICENSE)


**Authors:**
Matthew Armbruster


**Source:** [source/db_constraints/utils/meta.d](https://github.com/marmy28/db_constraints/tree/master/source/db_constraints/utils/meta.d)



***
<a name="opAAKey" href="#opAAKey"></a>
```d
template opAAKey(T) if (is(T == struct))
```

Used in KeyedItem for the generated structs.
This allows the struct to be used as a key
in an associative array.


The template loops over the members to define
toHash, opEquals, and opCmp for the struct.


***
<a name="GetUniqueConstraintStructNames" href="#GetUniqueConstraintStructNames"></a>
```d
template GetUniqueConstraintStructNames(ClassName)
```

Gets the names given to the different UniqueConstraints for ClassName.
The UniqueConstraintColumns are usually put on getters and setters.

**Returns:**
AliasSeq of all the distinct UniqueConstraintColumn.name in ClassName


***
<a name="GetMembersWithUDA" href="#GetMembersWithUDA"></a>
```d
template GetMembersWithUDA(ClassName, attribute)
```

Gets the properties of ClassName marked with @attribute. If the
attribute is PrimaryKeyColumn then it also confirms the property has
NotNull.

**Returns:**
AliasSeq with distinct properties that have @attribute assigned to it.


***
<a name="hasMembersWithUDA" href="#hasMembersWithUDA"></a>
```d
enum auto hasMembersWithUDA(ClassName, attribute);

```

Confirms there are members in ClassName with @attribute.

**Returns:**
true if there are members that have @attribute


***
<a name="GetForeignKeys" href="#GetForeignKeys"></a>
```d
template GetForeignKeys(ClassName)
```

Gets all of the [ForeignKey](https://github.com/marmy28/db_constraints/wiki/constraints#ForeignKey) that ClassName is attributed with. If
the foreign key name is left blank then the default name is `"fk_" ~ ClassName ~ "_" ~ referencedClassName`.


***
<a name="hasForeignKeys" href="#hasForeignKeys"></a>
```d
enum auto hasForeignKeys(ClassName);

```

Confirms ClassName has foreign keys.

**Returns:**
true if ClassName has an instance of @ForeignKey


***
<a name="GetForeignKeyRefTable" href="#GetForeignKeyRefTable"></a>
```d
template GetForeignKeyRefTable(ClassName) if (hasForeignKeys!ClassName)
```

Gets all of the referenced foreign keys for ClassName.

**Returns:**
Distinct list of all referenced classes for ClassName.


***
<a name="GetDefault" href="#GetDefault"></a>
```d
template GetDefault(ClassName, string memberName) if (hasDefault!(ClassName, memberName))
```

Gets the value for ClassName.memberName inside of @Default!(value) if memberName has @Default!(value)


***
<a name="hasDefault" href="#hasDefault"></a>
```d
template hasDefault(ClassName, string memberName)
```

Confirms ClassName.memberName has @Default!(value)

**Returns:**
true if ClassName.memberName has @Default!(value)


***
<a name="createForeignKeyPropertyConverter" href="#createForeignKeyPropertyConverter"></a>
```d
string createForeignKeyPropertyConverter(ClassName)();

```

Creates the foreign key properties inside of `KeyedItem`
that convert the keyed items properties into the necessary
foreign key clustered index.


***
<a name="createForeignKeyProperties" href="#createForeignKeyProperties"></a>
```d
string createForeignKeyProperties(ClassName)();

```

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


***
<a name="createForeignKeyCheckExceptions" href="#createForeignKeyCheckExceptions"></a>
```d
string createForeignKeyCheckExceptions(ClassName)();

```

Creates the foreign key check exceptions by seeing if the foreign key has been associated and
whether or not the referenced table has a matching record.


***
<a name="createForeignKeyChanged" href="#createForeignKeyChanged"></a>
```d
string createForeignKeyChanged(ClassName)();

```

Creates the foreign keys update rule and delete rule property and sets them to the foreign key attribute property.
It also creates the function that will be attached to the foreign key when it is associated. This is where
the update rule and delete rule are used since the referenced class will emit what changed and to which item.


***
<a name="hasExclusionConstraints" href="#hasExclusionConstraints"></a>
```d
enum auto hasExclusionConstraints(ClassName);

```

Confirms ClassName has exclusion constraints.

**Returns:**
true if ClassName has an instance of @ExclusionConstraint


***
<a name="GetExclusionConstraints" href="#GetExclusionConstraints"></a>
```d
template GetExclusionConstraints(ClassName)
```

Gets all of the [ExclusionConstraint](https://github.com/marmy28/db_constraints/wiki/constraints#ExclusionConstraint) that ClassName is attributed with. If
the exclusion constraint name is left blank then the default name is `"exc_" ~ ClassName`.




Copyright :copyright: 2016 | Page generated by [Ddoc](http://dlang.org/ddoc.html) on Mon Mar  7 19:21:14 2016

