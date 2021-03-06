/**
The following examples come from
$(LINK http://zetcode.com/db/sqlite/constraints/).
Even though it is a SQLite tutorial the point is to show how to use this package
which does not have to be just SQLite.
 */
module test.examples_default;

version(D_Ddoc)
{
    ///
    class BlankClassSoDocsWillBeGenerated { }
}


/**
This example is for the DEFAULT constraint. The table
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
