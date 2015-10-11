module tests.person;

version(D_Ddoc)
{
    /// Really important class
    class Example { }
}
/**
This is just an example of stuff
 */
unittest
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
        @UniqueConstraintColumn!("uc_Person")
        @property string firstName() const nothrow pure @safe @nogc
        {
            return _firstName;
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

        this(string firstName_, string lastName_, string email_)
        {
            static int i = 1;
            this._id = i;
            this._firstName = firstName_;
            this._lastName = lastName_;
            this._email = email_;
            ++i;
            initializeKeyedItem();
        }
        Person dup()
        {
            return new Person(this._firstName, this._lastName, this._email);
        }
        mixin KeyedItem!(UniqueConstraintColumn!("uc_PersonEmail"));
    }

    {
        alias People = BaseKeyedCollection!(Person);
        auto people = new People([new Person("Valid", "Person", "vp@test.com"), new Person("Second", "Sup", "s@e.org")]);
        assert(people.contains("s@e.org"));
        //assert(!people.contains(null));
        people["s@e.org"].email = "hello@all";
        assert(people.contains("hello@all"));
        people["hello@all"].email = null;
        assert(!people.contains("s@e.org"));
        assert(!people.contains("hello@all"));
        auto i = Person.uc_PersonEmail();
        i.email = null;
        assert(people.contains(i));
    }
}
