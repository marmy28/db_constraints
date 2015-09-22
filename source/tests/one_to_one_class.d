/**
This is an example of a one-to-one relationship. I am trying
to brainstorm how I should do foreign keys so this is my current
prototype. I will need to put the foreign key elements in the
keyed item and then just mark the columns that are part of the
foreign key with the necessary information.
 */
module tests.one_to_one_class;

import db_constraints;

version(unittest)
{
    ///Fake class
    class JustForDocs
    {
    }
}

///
unittest
{
    class Human
    {
    private:
        string _name;
    public:
        @PrimaryKeyColumn
        string name() const @property nothrow pure @safe @nogc
        {
            return _name;
        }
        void name(string value) @property
        {
            setter(_name, value);
        }
        this(string name_)
        {
            this._name = name_;
            initializeKeyedItem();
        }
        Human dup()
        {
            return new Human(this.name);
        }
        override bool opEquals(Object o) const pure nothrow @nogc
        {
            auto rhs = cast(immutable Human)o;
            return (rhs !is null && this.key == rhs.key);
        }

        mixin KeyedItem!(typeof(this));
    }
    class Humans : BaseKeyedCollection!Human
    {
        this(Human item)
        {
            super(item);
        }
        this(Human[] items)
        {
            super(items);
        }
    }

    class Phone
    {
    private:
        string _name_h;
        Human *_human;
    public:
        @UniqueConstraintColumn!("human_phone_name")
        string name_h() const @property nothrow pure @safe @nogc
        {
            return _name_h;
        }
        void name_h(string value) @property
        {
            setter(_name_h, value);
        }

        string brand;

        // foreign key struct
        Human *human() @property nothrow pure @safe @nogc
        {
            return _human;
        }
        void human(Human *value) @property
        {
            if (value !is _human)
            {
                if (_human !is null)
                {
                    this._human.emitChange.disconnect(&foreignKeyChanged);
                }
                this._human = value;
                if (_human !is null)
                {
                    this._human.emitChange.connect(&foreignKeyChanged);
                    this.name_h = _human.name;
                }
                notify!("human");
            }
        }
        ForeignKeyActions onUpdate = ForeignKeyActions.noAction;
        ForeignKeyActions onDelete = ForeignKeyActions.cascade;
        void foreignKeyChanged(string propertyName, typeof(Human.key) item_key)
        {
            if (propertyName == "name")
            {
                final switch (onUpdate) with (ForeignKeyActions)
                {
                case noAction:
                    version(noActionIsRestrict)
                    {
                        goto case restrict;
                    }
                    else
                    {
                        // not doing anything
                        break;
                    }
                case restrict:
                    if (this.human.name != this.name_h)
                    {
                        throw new ForeignKeyException("ForeignKeyActions.restrict violation.");
                    }
                    break;
                case setNull:
                    static if (__traits(compiles, this.name_h = null))
                    {
                        this.name_h = null;
                        break;
                    }
                    else
                    {
                        throw new ForeignKeyException("Cannot use ForeignKeyActions.setNull " ~
                                                      "when the member cannot be set to null.");
                    }
                case setDefault:
                    // somehow get the default if one is set...
                    this.name_h = typeof(this.name_h).init;
                    break;
                case cascade:
                    this.name_h = this.human.name;
                    break;
                }
            }
        }

        this(string name_, string brand_)
        {
            this._name_h = name_;
            this.brand = brand_;
            initializeKeyedItem();
        }
        Phone dup()
        {
            return new Phone(this.name_h, this.brand);
        }
        override bool opEquals(Object o) const pure nothrow @nogc
        {
            auto rhs = cast(immutable Phone)o;
            return (rhs !is null && this.key == rhs.key);
        }

        mixin KeyedItem!(typeof(this), UniqueConstraintColumn!("human_phone_name"));
    }

    // move foreignkeychanged into the plural class
    class Phones : BaseKeyedCollection!Phone
    {
        this(Phone item)
        {
            super(item);
        }
        this(Phone[] items)
        {
            super(items);
        }

        ForeignKeyActions onUpdate = ForeignKeyActions.noAction;
        ForeignKeyActions onDelete = ForeignKeyActions.noAction;
        void associateParent(Humans humans_)
        {
            this._humans = &humans_;
            import std.algorithm : filter;
            if (humans_ !is null)
            {
                import std.parallelism;
                foreach(ref item; taskPool.parallel(this.byValue))
                {
                    auto human = humans_.byValue.filter!(a => a.name == item.name_h);
                    if (!human.empty)
                    {
                        item.human = &(human.front());
                    }
                }
            }
        }
    protected:
        override void itemChanged(string propertyName, key_type item_key)
        {
            std.stdio.writeln(propertyName);
            super.itemChanged(propertyName, item_key);
        }
        Humans *_humans;
    }

    auto i = new Human("Dave");
    assert(!i.containsChanges());
    auto j = new Phone(null, "Apple");
    j.human = &i;
    assert(i.name == "Dave");
    assert(i == *j.human);
    assert(j.name_h == i.name);
    j.onUpdate = ForeignKeyActions.cascade;
    i.name = "David";
    assert(i == *j.human);
    assert(i.name == j.human.name);
    assert(j.name_h == i.name);
    j.onUpdate = ForeignKeyActions.noAction;
    i.name = "Tom";
    assert(i.name != j.name_h);
    j.name_h = "Tom";

    j.onUpdate = ForeignKeyActions.restrict;
    import std.exception : assertThrown;
    assertThrown!ForeignKeyException(i.name = "Dave");



    auto humans = new Humans([new Human("Anne"), new Human("Dave"),
                              new Human("Deb"), new Human("Jane")]);
    auto phones = new Phones([new Phone("Dave", "Apple"),
                              new Phone("Deb", "Flip"),
                              new Phone("Anne", "Ubuntu")]);

    foreach(phone; phones)
    {
        assert(phone.human is null);
        phone.onUpdate = ForeignKeyActions.cascade;
        phone.onDelete = ForeignKeyActions.cascade;
    }

    phones.associateParent(humans);
    foreach(phone; phones)
    {
        assert(phone.human !is null);
        assert(phone.human.name == phone.name_h);
    }

}
