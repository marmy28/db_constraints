/**
The following examples come from
$(LINK http://zetcode.com/db/sqlite/constraints/).
Even though it is a SQLite tutorial the point is to show how to use this package
which does not have to be just SQLite.
 */
module test.examples_from_zetcode3;

version(D_Ddoc)
{
    ///
    class BlankClassSoDocsWillBeGenerated { }
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

    // but we will get an error if we try to change it to
    // something below 0 again
    assertThrown!CheckConstraintException(i.OrderPrice = -1);
}
