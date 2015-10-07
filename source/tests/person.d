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
        override string toString()
        {
            auto result = this._firstName ~ " " ~ this._lastName ~ " email: " ~ (this._email is null ? "null" : this._email);
            return result;
        }
        mixin KeyedItem!(UniqueConstraintColumn!("uc_PersonEmail"));
    }
}

unittest
{
    import db_constraints;
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
    // assert(people.contains(null)); // currently this errors but it should not
}
