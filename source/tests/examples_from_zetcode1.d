/**
The following examples come from
$(LINK http://zetcode.com/db/sqlite/constraints/).
Even though it is a SQLite tutorial the point is to show how to use this package
which does not have to be just SQLite.
 */
module test.examples_from_zetcode1;

version(D_Ddoc)
{
    ///
    class BlankClassSoDocsWillBeGenerated { }
}

/**
The first example is for the NOT NULL constraint. The table
in SQL can be created by
$(D $(D $(D sql
CREATE TABLE People
(
    Id INTEGER NOT NULL PRIMARY KEY,
    LastName TEXT NOT NULL,
    FirstName TEXT NOT NULL,
    City TEXT
);

)))

I will create the singular class (or row class). The singular class
should include a dup method and the mixin KeyedItem. The columns in the
singular class should have a private member with getters and setters. No
plural class (or table class) is needed for this example.

In making this package, I have made the assumption that the private member
begins with an underscore and the getters and setters have the same name
as the private member except no beginning underscore.
The keyed item must also have some Unique constraint and will not compile
without one.

The setter method provided in KeyedItem should be used in your setters. This
will check if you are setting it to the same value, if the value causes any
check constraints to be violated and if everything goes well notifies the
plural class (or table) of the changes.
 */
unittest
{
    import db_constraints;

    // this is what I call the singular class
    // you can also think of it as a row in the database.
    // it contains all of the columns and tells us which
    // columns have which constraints
    class Person
    {
        private int _Id;
        // marking Id with not null and primary key
        @NotNull @PrimaryKeyColumn
        @property int Id()
        {
            return _Id;
        }
        @property void Id(int value)
        {
            setter(_Id, value);
        }

        private string _LastName;
        // marking LastName with not null
        @NotNull
        @property string LastName()
        {
            return _LastName;
        }
        @property void LastName(string value)
        {
            setter(_LastName, value);
        }

        private string _FirstName;
        // marking FirstName with not null
        @NotNull
        @property string FirstName()
        {
            return _FirstName;
        }
        @property void FirstName(string value)
        {
            setter(_FirstName, value);
        }

        private string _City;
        // not marking City with anything
        @property string City()
        {
            return _City;
        }
        @property void City(string value)
        {
            setter(_City, value);
        }

        this(int Id_, string LastName_, string FirstName_, string City_)
        {
            this._Id = Id_;
            this._LastName = LastName_;
            this._FirstName = FirstName_;
            this._City = City_;
            // do not forget to initialize the keyed item!
            initializeKeyedItem();
        }

        Person dup()
        {
            return new Person(this._Id, this._LastName,
                              this._FirstName, this._City);
        }

        // the keyed item mixin will create all the necessary
        // checks for you
        mixin KeyedItem!();
    }


    import std.exception : assertNotThrown, assertThrown;
    // I will make a single row with values for all columns
    // this does not throw an exception because none of the
    // check constraints are violated.
    assertNotThrown!CheckConstraintException(new Person(1, "Hanks",
                                                        "Robert", "New York"));

    // the next Person throws a check constraint exception
    // since we try to make a Person that has a null LastName
    assertThrown!CheckConstraintException(new Person(2, null,
                                                     "Marianne", "Chicago"));
}
