/**
The following examples come from
$(LINK http://zetcode.com/databases/mysqltutorial/constraints/).
 */
module test.examples_enum_constraint;

version(D_Ddoc)
{
    ///
    class BlankClassSoDocsWillBeGenerated { }
}


/**
This example is for the ENUM constraints. The table
in SQL can be created by
$(D $(D $(D sql
CREATE TABLE Shops
(
    Id INTEGER NOT NULL PRIMARY KEY,
    Name VARCHAR(55),
    Quality ENUM('High', 'Average', 'Low')
);

)))
 */
unittest
{
    import db_constraints;

    class Shop
    {
        private int _Id;
        @PrimaryKeyColumn @NotNull
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
        private string _Quality;
        // Quality can only have a value that
        // is among the enumeration below.
        // Using false so this will not throw an
        // exception but instead just change _Quality
        // to an empty string.
        @EnumConstraint!(false, "High", "Average", "Low")
        @property string Quality()
        {
            return _Quality;
        }
        @property void Quality(string value)
        {
            setter(_Quality, value);
        }
        this(int Id_, string Name_, string Quality_)
        {
            this._Id = Id_;
            this._Name = Name_;
            this._Quality = Quality_;
            initializeKeyedItem();
        }

        mixin KeyedItem!();
    }

    auto Boneys = new Shop(1, "Boneys", "High");
    assert(Boneys.Quality == "High");

    auto ACRiver = new Shop(2, "AC River", "Average");
    assert(ACRiver.Quality == "Average");

    auto AT34 = new Shop(3, "AT 34", "**");
    // since we have this as a non-strict enum, the
    // quality is set to an empty string when
    // given a string that is not in the enumeration
    assert(AT34.Quality == "");
}
