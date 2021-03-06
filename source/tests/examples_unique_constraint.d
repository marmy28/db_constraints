/**
The following examples come from
$(LINK http://zetcode.com/db/sqlite/constraints/).
Even though it is a SQLite tutorial the point is to show how to use this package
which does not have to be just SQLite.
 */
module test.examples_unique_constraint;

version(D_Ddoc)
{
    ///
    class BlankClassSoDocsWillBeGenerated { }
}


/**
This example is for the UNIQUE constraint and the PRIMARY KEY constraint.
The table in SQL can be created by
$(D $(D $(D sql
CREATE TABLE Brands
(
    Id INTEGER NOT NULL PRIMARY KEY,
    BrandName TEXT UNIQUE
);

)))

Any column marked with @PrimaryKeyColumn must also have @NotNull. Unlike SQLite,
if a column is marked as int and @PrimaryKeyColumn it is not auto-incremented.
 */
unittest
{
    import db_constraints;

    class Brand
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

        private string _BrandName;
        // marking BrandName with UniqueConstraintColumn
        // so the collection will know this property should be
        // unique for all records
        @UniqueConstraintColumn!("Unique")
        @property string BrandName()
        {
            return _BrandName;
        }
        @property void BrandName(string value)
        {
            setter(_BrandName, value);
        }

        this(int Id_, string BrandName_)
        {
            this._Id = Id_;
            this._BrandName = BrandName_;
            // do not forget to initialize the keyed item!
            initializeKeyedItem();
        }

        // do not forget to add in the keyed item!
        mixin KeyedItem!();
    }

    // this is what I call the plural class
    // or table class. This is the collection
    // of rows (in this example Brands).
    class Brands
    {
        // this mixin already does the
        // initializations and every method
        // I want for this tutorial so I
        // do not need anything else.
        mixin KeyedCollection!(Brand);
    }

    import std.exception : assertNotThrown, assertThrown;

    // UNIQUE constraint
    {
        // we can start by putting two records into the collection.
        // now brands holds a record for Coca Cola and Pepsi
        auto brands = new Brands([new Brand(1, "Coca Cola"),
                                  new Brand(2, "Pepsi")]);

        auto anotherPepsi = new Brand(3, "Pepsi");
        // if we try to add another record that has Pepsi for
        // the brand name we will get a unique constraint exception
        assertThrown!UniqueConstraintException(brands.add(anotherPepsi));

        // we can see if the new record will violate any unique constraints
        // before we add it to the collection by using violatesUniqueConstraints
        assert(brands.violatesUniqueConstraints(anotherPepsi));
    }

    // PRIMARY KEY constraint
    {
        // the primary key is unique and not null
        // by default we can use the primary key to look up
        // records in the collection
        auto brands = new Brands([new Brand(1, "Coca Cola"),
                                  new Brand(2, "Pepsi")]);

        // since Pepsi's Id is the primary key we can use 2 to find pepsi
        assert(brands[2].BrandName == "Pepsi");
        assert(brands[2].Id == 2);
        // this is because brands is really an associative array that uses the
        // primary key in this case as the AA key. We can check if the
        // collection already contains a primary key of 2 by using contains
        assert(brands.contains(2));
        // and does not contain 4
        assert(!brands.contains(4));
        // if you try to get an item that is not there you will get an exception
        assertThrown!KeyedException(brands[4].BrandName);

        // lets add two more records
        brands ~= [new Brand(3, "Sun"), new Brand(4, "Oracle")];

        // now it does contain 4
        assert(brands.contains(4));
        assertNotThrown!KeyedException(brands[4].BrandName);
    }
}
