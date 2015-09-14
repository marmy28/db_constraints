/**
This is an example of a one-to-one relationship. I am trying
to brainstorm how I should do foreign keys so this is my current
prototype. I will need to put the foreign key elements in the
keyed item and then just mark the columns that are part of the
foreign key with the necessary information.
 */
module tests.one_to_one_class;

import db_extensions;

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
            if (value != _name)
            {
                _name = value;
                notify("name");
            }
        }
        this(string name_)
        {
            this._name = name_;
            setClusteredIndex();
        }

        mixin KeyedItem!(typeof(this));
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
            if (value != this.name_h)
            {
                _name_h = value;
                notify("name_h");
            }
        }

        string brand;

        // foreign key struct
        Human human() @property nothrow pure @safe @nogc
        {
            return *_human;
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
                notify("human");
            }
        }
        ForeignKeyActions onUpdate = ForeignKeyActions.noAction;
        ForeignKeyActions onDelete = ForeignKeyActions.cascade;
        void foreignKeyChanged(string propertyName, typeof(Human.key) item_key)
        {
            if (propertyName == "PrimaryKey_key")
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
            setClusteredIndex();
        }

        mixin KeyedItem!(typeof(this), UniqueConstraintColumn!("human_phone_name"));
    }

    auto i = new Human("Dave");
    assert(!i.containsChanges());
    auto j = new Phone(null, "Apple");
    j.human = &i;
    assert(i.name == "Dave");
    assert(i == j.human);
    assert(j.name_h == i.name);
    j.onUpdate = ForeignKeyActions.cascade;
    i.name = "David";
    assert(i == j.human);
    assert(i.name == j.human.name);
    assert(j.name_h == i.name);
    j.onUpdate = ForeignKeyActions.noAction;
    i.name = "Tom";
    assert(i.name != j.name_h);
    j.name_h = "Tom";

    j.onUpdate = ForeignKeyActions.restrict;
    import std.exception : assertThrown;
    assertThrown!ForeignKeyException(i.name = "Dave");
}
