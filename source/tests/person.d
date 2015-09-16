module tests.person;

version(unittest)
{
    import db_extensions;
    class Person
    {
    private:
        int _id;
        string _firstName;
        string _lastName;
        string _email;
    public:
        int id() const @property @PrimaryKeyColumn nothrow pure @safe @nogc
        {
            return _id;
        }
        void id(immutable(int) value) @property
        {
            setter(_id, value, "id");
        }
        string firstName() const @property @UniqueConstraintColumn!("uc_Person") nothrow pure @safe @nogc
        {
            return _firstName;
        }
        void firstName(string value) @property
        {
            setter(_firstName, value, "firstName");
        }
        string email() const @property nothrow pure @UniqueConstraintColumn!("uc_PersonEmail") @safe @nogc
        {
            return _email;
        }
        void email(string value) @property
        {
            setter(_email, value, "email");
        }
        string lastName() const @property @UniqueConstraintColumn!("uc_Person") nothrow pure @safe @nogc
        {
            return _lastName;
        }
        void lastName(string value) @property
        {
            setter(_lastName, value, "lastName");
        }

        mixin KeyedItem!(typeof(this));
    }
}
