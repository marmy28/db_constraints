/**
The following examples come from $(LINK http://zetcode.com/db/sqlite/constraints/).
Even though it is a SQLite tutorial the point is to show how to use this package
which does not have to be just SQLite.
 */
module test.examples_from_zetcode;

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
            return new Person(this._Id, this._LastName, this._FirstName, this._City);
        }

        // the keyed item mixin will create all the necessary
        // checks for you
        mixin KeyedItem!();
    }


    import std.exception : assertNotThrown, assertThrown;
    // I will make a single row with values for all columns
    // this does not throw an exception because none of the check constraints are violated.
    assertNotThrown!CheckConstraintException(new Person(1, "Hanks", "Robert", "New York"));

    // the next Person throws a check constraint exception since we try to make a Person
    // that has a null LastName
    assertThrown!CheckConstraintException(new Person(2, null, "Marianne", "Chicago"));
}

/**
The second example is for the UNIQUE constraint and the PRIMARY KEY constraint. The table
in SQL can be created by
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

        Brand dup()
        {
            return new Brand(this._Id, this._BrandName);
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
        auto brands = new Brands([new Brand(1, "Coca Cola"), new Brand(2, "Pepsi")]);

        auto anotherPepsi = new Brand(3, "Pepsi");
        // if we try to add another record that has Pepsi for the brand name we will
        // get a unique constraint exception
        assertThrown!UniqueConstraintException(brands.add(anotherPepsi));

        // we can see if the new record will violate any unique constraints before
        // we add it to the collection by using violatesUniqueConstraints
        assert(brands.violatesUniqueConstraints(anotherPepsi));
    }

    // PRIMARY KEY constraint
    {
        // the primary key is unique and not null
        // by default we can use the primary key to look up
        // records in the collection
        auto brands = new Brands([new Brand(1, "Coca Cola"), new Brand(2, "Pepsi")]);

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

/**
The third example is for the CHECK constraint. The table
in SQL can be created by
$(D $(D $(D sql
CREATE TABLE Orders
(
    Id INTEGER NOT NULL PRIMARY KEY,
    OrderPrice INTEGER CHECK(OrderPrice > 0),
    Customer TEXT
);

)))
 */
unittest
{
    import db_constraints;

    class Order
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

        private int _OrderPrice;
        // marking OrderPrice with a check constraint
        // that makes sure OrderPrice is greater than 0
        @CheckConstraint!(a => a > 0)
        @property int OrderPrice()
        {
            return _OrderPrice;
        }
        @property void OrderPrice(int value)
        {
            setter(_OrderPrice, value);
        }

        private string _Customer;
        @property string Customer()
        {
            return _Customer;
        }
        @property void Customer(string value)
        {
            setter(_Customer, value);
        }

        this(int Id_, int OrderPrice_, string Customer_)
        {
            this._Id = Id_;
            this._OrderPrice = OrderPrice_;
            this._Customer = Customer_;
            initializeKeyedItem();
        }

        Order dup()
        {
            return new Order(this._Id, this._OrderPrice, this._Customer);
        }

        mixin KeyedItem!();
    }

    import std.exception : assertNotThrown, assertThrown;

    // throws because -10 is less than 0 and the check constraint does
    // not allow that.
    assertThrown!CheckConstraintException(new Order(1, -10, "Johnson"));

    // we can create a new order that will not error
    auto i = new Order(1, 10, "Johnson");
    // if we change the order price to another value still greater than
    // 0 we should not get an error
    assertNotThrown!CheckConstraintException(i.OrderPrice = 9);
    assert(i.OrderPrice == 9);

    // but we will get an error if we try to change it to something below 0 again
    assertThrown!CheckConstraintException(i.OrderPrice = -1);
}


/**
The fourth example is for the DEFAULT constraint. The table
in SQL can be created by
$(D $(D $(D sql
CREATE TABLE Hotels
(
    Id INTEGER NOT NULL PRIMARY KEY,
    Name TEXT,
    City TEXT DEFAULT 'not available'
);

)))

Default in this package was made for foreign key interactions. With that
in mind I know in this example it seems like I should just set
the default value in the setter but then my package would not know what
default you want for a foreign key update rule or delete rule.
 */
unittest
{
    import db_constraints;

    class Hotel
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


        private string _Name;
        @property string Name()
        {
            return _Name;
        }
        @property void Name(string value)
        {
            setter(_Name, value);
        }

        private string _City;
        // marking city with its default
        @Default!("not available")
        @property string City()
        {
            return _City;
        }
        @property void City(string value)
        {
            setter(_City, value);
        }

        this(int Id_, string Name_, string City_)
        {
            this._Id = Id_;
            this._Name = Name_;
            this._City = City_;
            initializeKeyedItem();
        }
        this(int Id_, string Name_)
        {
            this._Id = Id_;
            this._Name = Name_;
            // using GetDefault will get the value you
            // placed in the Default attribute
            this._City = GetDefault!(Hotel, "City");
            initializeKeyedItem();
        }

        Hotel dup()
        {
            return new Hotel(this._Id, this._Name, this._City);
        }

        mixin KeyedItem!();
    }

    // make sure Hotel.City has a default attribute
    assert(hasDefault!(Hotel, "City"));
    // the default attribute has value not available
    assert(GetDefault!(Hotel, "City") == "not available");

    auto i = new Hotel(1, "Kyjev", "Bratislava");
    assert(i.City == "Bratislava");
    // since City is not included in this constructor we use the default
    auto j = new Hotel(2, "Slovan");
    assert(j.City == "not available");
}
