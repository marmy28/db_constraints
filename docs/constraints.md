# db_constraints.constraints


User-defined attributes that can be used with the KeyedItem mixin.
The constraints module contains:
  + [UniqueConstraintColumn](#UniqueConstraintColumn)
  + [PrimaryKeyColumn](#PrimaryKeyColumn)
  + [ExclusionConstraint](#ExclusionConstraint)
  + [CheckConstraint](#CheckConstraint)
  + [NotNull](#NotNull)
  + [SetConstraint](#SetConstraint)
  + [EnumConstraint](#EnumConstraint)
  + [Rule](#Rule)
  + [ForeignKey](#ForeignKey)
  + [ForeignKeyConstraint](#ForeignKeyConstraint)
  + [Default](#Default)

**License:**
[GPL-2.0](https://github.com/marmy28/db_constraints/blob/master/LICENSE)


**Authors:**
Matthew Armbruster


**Source:** [source/db_constraints/constraints.d](https://github.com/marmy28/db_constraints/tree/master/source/db_constraints/constraints.d)


***
<a name="UniqueConstraintColumn" href="#UniqueConstraintColumn"></a>
```d
struct UniqueConstraintColumn(string name_);

```

KeyedItem will create a struct with _name_ defined in the compile-time
argument. For example a property marked with @UniqueColumn!("uc_Person") will
be part of the struct uc_Person.

Parameters |
---|
*name_*|
&nbsp;&nbsp;&nbsp;&nbsp;The name of the constraint which is the structs name|



***
<a name="PrimaryKeyColumn" href="#PrimaryKeyColumn"></a>
```d
alias PrimaryKeyColumn = UniqueConstraintColumn!"PrimaryKey".UniqueConstraintColumn;

```

An alias for the primary key column. A member with this attribute
must also have the NotNull attribute.


***
<a name="ExclusionConstraint" href="#ExclusionConstraint"></a>
```d
struct ExclusionConstraint(alias exclusion_, string name_ = "") if (is(typeof(binaryFun!exclusion_)));

```

Mimics Postgresql's Exclude Constraint. This will exclude any
items that return true to the `exclusion_`.

**Version:**
\>= 0.0.7


***
<a name="CheckConstraint" href="#CheckConstraint"></a>
```d
struct CheckConstraint(alias check_, string name_ = "") if (is(typeof(unaryFun!check_)));

```

[KeyedItem.checkConstraints](https://github.com/marmy28/db_constraints/wiki/keyeditem#KeyedItem.checkConstraints) will check all of the members
marked with this attribute and use the check given.

**Version:**
\>= 0.0.6 allows you to mark your class as well.


Parameters |
---|
*check_*|
&nbsp;&nbsp;&nbsp;&nbsp;The function that returns a boolean|
*name_*|
&nbsp;&nbsp;&nbsp;&nbsp;Name used in the error message if the function returns false|



***
<a name="NotNull" href="#NotNull"></a>
```d
alias NotNull = CheckConstraint!(function bool(auto ref a)
{
static if (__traits(hasMember, typeof(a), "isNull"))
{
return !a.isNull;
}
else
{
static if (__traits(compiles, (typeof(a)).init == null))
{
return a !is null;
}
else
{
return true;
}
}
}
, "NotNull").CheckConstraint;

```

Alias for a special check constraint that makes sure the column is never null.
This is checked the same time as all the other check constraints. The name of
the constraint is NotNull in the error messages if this is ever violated.


***
<a name="SetConstraint" href="#SetConstraint"></a>
```d
template SetConstraint(values...) if (isExpressions!values)
template SetConstraint(bool isStrict, values...) if (isExpressions!values)
```

Alias for check constraint that makes sure the property that
has this attribute only contains members in the set. This should
act like the SET constraint in MySQL. It will sort and remove the
duplicates of the SET. This does modify the value coming in. This
is only for strings.


If `isStrict` is true, SetConstraint will return false if
you include a value not in the set. If `isStrict` is
false, the value will be set to an empty string.


**Version:**
\>= 0.0.6 for `isStrict` option.
\>= 0.0.4 is always strict.


***
<a name="EnumConstraint" href="#EnumConstraint"></a>
```d
template EnumConstraint(values...) if (isExpressions!values)
template EnumConstraint(bool isStrict, values...) if (isExpressions!values)
```

Alias for check constraint that makes sure the property that
has this attribute only contains a member that is part of the
enumeration. This should act like the ENUM constraint in MySQL.
This does modify the value coming in. This is only for strings.


If `isStrict` is true, EnumConstraint will return false if
you include a value not in the enumeration. If `isStrict` is
false, the value will be set to an empty string.


**Version:**
\>= 0.0.6


***
<a name="Rule" href="#Rule"></a>
```d
enum Rule: int;

```

Rules for foreign keys when updating or deleting.

***
<a name="Rule.noAction" href="#Rule.noAction"></a>
```d
noAction
```

When a parent key is modified or deleted from the collection, no special
action is taken. If you are using MySQL or MSSQL use
[Rule.restrict](#Rule.restrict) instead for the desired effect.


***
<a name="Rule.restrict" href="#Rule.restrict"></a>
```d
restrict
```

The item is prohibited from deleting or modifying a parent key when there exists
one or more child keys mapped to it. This is the default.


:exclamation: **Throws:**
[ForeignKeyException](https://github.com/marmy28/db_constraints/wiki/db_exceptions#ForeignKeyException) when a member changes.


***
<a name="Rule.setNull" href="#Rule.setNull"></a>
```d
setNull
```

Sets the member to `null` when deleting or modifying a parent key.


:exclamation: **Throws:**
[ForeignKeyException](https://github.com/marmy28/db_constraints/wiki/db_exceptions#ForeignKeyException) when the type cannot be set to null.


***
<a name="Rule.setDefault" href="#Rule.setDefault"></a>
```d
setDefault
```

Sets the member to the Default value when deleting or modifying a parent key.
If there is no defined Default then the member is set to its types initial
value.


***
<a name="Rule.cascade" href="#Rule.cascade"></a>
```d
cascade
```

Updates or deletes the item based on what happened to the parent key.




***
<a name="ForeignKey" href="#ForeignKey"></a>
```d
struct ForeignKey(string name_, string[] columnNames_, string referencedTableName_, string[] referencedColumnNames_, Rule updateRule_, Rule deleteRule_);

```

[ForeignKeyConstraint](#ForeignKeyConstraint) should be used instead of this struct.
This is more the behind the scenes struct.

Parameters |
---|
*name_*|
&nbsp;&nbsp;&nbsp;&nbsp;The name of the foreign key constraint. Will be used in error message when violated|
*columnNames_*|
&nbsp;&nbsp;&nbsp;&nbsp;The members in the child class that are used in the foreign key|
*referencedTableName_*|
&nbsp;&nbsp;&nbsp;&nbsp;The referenced table's name (collection class)|
*referencedColumnNames_*|
&nbsp;&nbsp;&nbsp;&nbsp;The members in the parent class that are references in the foreign key|
*updateRule_*|
&nbsp;&nbsp;&nbsp;&nbsp;Rule when a foreign key is updated that is being referenced|
*deleteRule_*|
&nbsp;&nbsp;&nbsp;&nbsp;Rule when a foreign key is deleted that is being referenced|



***
<a name="ForeignKeyConstraint" href="#ForeignKeyConstraint"></a>
```d
template ForeignKeyConstraint(string name_, string[] columnNames_, string referencedTableName_, string[] referencedColumnNames_, Rule updateRule_, Rule deleteRule_)
template ForeignKeyConstraint(string name_, string[] columnNames_, string referencedTableName_, string[] referencedColumnNames_)
template ForeignKeyConstraint(string[] columnNames_, string referencedTableName_, string[] referencedColumnNames_, Rule updateRule_, Rule deleteRule_)
template ForeignKeyConstraint(string[] columnNames_, string referencedTableName_, string[] referencedColumnNames_)
```

The foreign key user-defined attribute.


***
<a name="Default" href="#Default"></a>
```d
struct Default(alias value_);

```

Default used with [Rule.setDefault](#Rule.setDefault) for foreign keys.

Parameters |
---|
*value_*|
&nbsp;&nbsp;&nbsp;&nbsp;the value that should be used for the default value.|





Copyright :copyright: 2016 | Page generated by [Ddoc](http://dlang.org/ddoc.html) on Mon Mar  7 19:21:14 2016

