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
        @PrimaryKeyColumn @NotNull
        @property Nullable!int id() const nothrow pure @safe @nogc
        {
            return _id;
        }
        @property void id(Nullable!(int) value)
        {
            setter(_id, value);
        }
        @UniqueConstraintColumn!("uc_Person")
        @property string firstName() const nothrow pure @safe @nogc
        {
            return _firstName;
        }
        @property void firstName(string value)
        {
            setter(_firstName, value);
        }
        @UniqueConstraintColumn!("uc_PersonEmail")
        @property string email() const nothrow pure @safe @nogc
        {
            return _email;
        }
        @property void email(string value)
        {
            setter(_email, value);
        }
        @UniqueConstraintColumn!("uc_Person")
        @property string lastName() const nothrow pure @safe @nogc
        {
            return _lastName;
        }
        @property void lastName(string value)
        {
            setter(_lastName, value);
        }

        mixin KeyedItem!();
    }
}
