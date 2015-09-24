module tests.person;

version(unittest)
{
    import db_constraints;
    class Person
    {
    private:
        Nullable!int _id;
        string _firstName;
        string _lastName;
        string _email;
    public:
        @NotNull
        Nullable!int id() const @property @PrimaryKeyColumn nothrow pure @safe @nogc
        {
            return _id;
        }
        void id(Nullable!(int) value) @property
        {
            setter(_id, value);
        }
        string firstName() const @property @UniqueConstraintColumn!("uc_Person") nothrow pure @safe @nogc
        {
            return _firstName;
        }
        void firstName(string value) @property
        {
            setter(_firstName, value);
        }
        string email() const @property nothrow pure @UniqueConstraintColumn!("uc_PersonEmail") @safe @nogc
        {
            return _email;
        }
        void email(string value) @property
        {
            setter(_email, value);
        }
        string lastName() const @property @UniqueConstraintColumn!("uc_Person") nothrow pure @safe @nogc
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
