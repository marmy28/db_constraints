/**
The following example comes from
$(LINK http://thoughts.davisjeff.com/2010/09/25/exclusion-constraints-are-generalized-sql-unique/).
 */
module test.examples_exclusion_constraint;

version(D_Ddoc)
{
    ///
    class BlankClassSoDocsWillBeGenerated { }
}

/**
This example is for the EXCLUSION constraint in Postgresql.
I will do an example with overlapping date ranges.
The table in SQL can be created by
$(D $(D $(D sql
CREATE TABLE b
(
    id INTEGER NOT NULL PRIMARY KEY,
    p PERIOD
);
ALTER TABLE b ADD EXCLUDE USING gist (p WITH &&);

)))
 */
unittest
{
    import std.datetime;
    
    import db_constraints;

    struct Period
    {
        Date startDate;
        Date endDate;

        invariant
        {
            assert(startDate <= endDate);
        }

        bool overlapsWith(in Period i)
        {
            return false;
        }
    }

    @ExclusionConstraint!((a, b) => a.p.overlapsWith(b.p))
    class B
    {
        private int _id;
        // marking id with not null and primary key
        @NotNull @PrimaryKeyColumn
        @property int id()
        {
            return _id;
        }
        @property void id(int value)
        {
            setter(_id, value);
        }

        private Period _p;
        @property inout(Period) p() inout // pure nothrow @nogc @safe
        {
            return _p;
        }
        @property void p(Period value)
        {
            setter(_p, value);
        }

        this(int id_, Period p_)
        {
            this._id = id_;
            this._p = p_;
            // do not forget to initialize the keyed item!
            initializeKeyedItem();
        }

        // do not forget to add in the keyed item!
        mixin KeyedItem!();
    }

    alias Bs = BaseKeyedCollection!(B);
// INSERT INTO b VALUES('[2009-01-05, 2009-01-10)');
// INSERT INTO b VALUES('[2009-01-07, 2009-01-12)');
    import std.exception : assertNotThrown, assertThrown;

}
