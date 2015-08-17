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
        int id() const @property @PrimaryKeyColumn() nothrow pure @safe @nogc
        {
            return _id;
        }
        void id(immutable(int) value) @property
        {
            if (value != _id)
            {
                _id = value;
                notify("id");
            }
        }
        string firstName() const @property @UniqueColumn!("uc_Person") nothrow pure @safe @nogc
        {
            return _firstName;
        }
        void firstName(string value) @property
        {
            if (value != _firstName)
            {
                _firstName = value;
                notify("firstName");
            }
        }
        string lastName() const @property @UniqueColumn!("uc_Person") nothrow pure @safe @nogc
        {
            return _lastName;
        }
        void lastName(string value) @property
        {
            if (value != _lastName)
            {
                _lastName = value;
                notify("lastName");
            }
        }
        string email() const @property nothrow pure @UniqueColumn!("uc_Person") @safe @nogc
        {
            return _lastName;
        }
        void email(string value) @property
        {
            if (value != _email)
            {
                _email = value;
                notify("email");
            }
        }

        mixin KeyedItem!(typeof(this));
    }
}
