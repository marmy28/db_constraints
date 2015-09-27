module tests.person;

version(unittest)
{
    import db_constraints;
    class Person
    {
    private:
        DBNullable!int _id;
        string _firstName;
        string _lastName;
        string _email;
    public:
        @PrimaryKeyColumn @NotNull
        DBNullable!int id() const @property nothrow pure @safe @nogc
        {
            return _id;
        }
        void id(DBNullable!(int) value) @property
        {
            setter(_id, value);
        }
        @UniqueConstraintColumn!("uc_Person")
        string firstName() const @property nothrow pure @safe @nogc
        {
            return _firstName;
        }
        void firstName(string value) @property
        {
            setter(_firstName, value);
        }
        @UniqueConstraintColumn!("uc_PersonEmail")
        string email() const @property nothrow pure @safe @nogc
        {
            return _email;
        }
        void email(string value) @property
        {
            setter(_email, value);
        }
        @UniqueConstraintColumn!("uc_Person")
        string lastName() const @property nothrow pure @safe @nogc
        {
            return _lastName;
        }
        void lastName(string value) @property
        {
            setter(_lastName, value);
        }

        mixin KeyedItem!(typeof(this));
    }
}
