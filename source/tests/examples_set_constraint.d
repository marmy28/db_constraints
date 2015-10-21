/**
The following examples come from
$(LINK http://zetcode.com/databases/mysqltutorial/constraints/).
 */
module test.examples_set_constraint;

version(D_Ddoc)
{
    ///
    class BlankClassSoDocsWillBeGenerated { }
}


/**
The sixth example is for the SET constraints. The table
in SQL can be created by
$(D $(D $(D sql
CREATE TABLE Students
(
    Id INTEGER NOT NULL PRIMARY KEY,
    Name VARCHAR(55),
    Certificates SET('A1', 'A2', 'B1', 'C1')
);

)))
 */
unittest
{
    import db_constraints;

    class Student
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
        private string _Certificates;
        // Certificates can only have values that
        // are among the set below.
        @SetConstraint!("A1", "A2", "B1", "C1")
        @property string Certificates()
        {
            return _Certificates;
        }
        @property void Certificates(string value)
        {
            setter(_Certificates, value);
        }
        this(int Id_, string Name_, string Certificates_)
        {
            this._Id = Id_;
            this._Name = Name_;
            this._Certificates = Certificates_;
            initializeKeyedItem();
        }

        mixin KeyedItem!();
    }

    // A1 and B1 are both allowed in the set so no error is raise here
    auto paul = new Student(1, "Paul", "A1,B1");
    // we can see paul's certificates are the same as they came in
    assert(paul.Certificates == "A1,B1");

    // all of jane's certificates are acceptable but not in order
    auto jane = new Student(2, "Jane", "A1,B1,A2");
    // the set constraint sorts the certificates for you
    assert(jane.Certificates == "A1,A2,B1");

    // now lets try with some duplicates
    jane.Certificates = "A1,A2,B1,A1";
    // the set constraint will also remove duplicates
    assert(jane.Certificates == "A1,A2,B1");

    // if we enter in certificates that are not allowed we should expect an exception
    import std.exception : assertThrown;
    assertThrown!CheckConstraintException(new Student(3, "Mark", "A1,A2,D1,D2"));
}
