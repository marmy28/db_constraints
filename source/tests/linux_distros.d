module test.linux_distros;

unittest
{
    import db_constraints;

    class Distros
    {
        class Distro
        {
            private int _id;
            private string _name;
            @PrimaryKeyColumn @NotNull
            @property int id()
            {
                return _id;
            }
            @property void id(int value)
            {
                setter(_id, value);
            }
            @UniqueConstraintColumn!("uc_Distros_name")
            @property string name()
            {
                return _name;
            }
            @property void name(string value)
            {
                // this._name = value;
                // this._containsChanges = true;
                // this.outer.itemChanged("name", this._key);
                // this.outer.itemChanged("uc_Distros_name_key", this._key);
                setter(_name, value);
            }
            this(int id_, string name_)
            {
                this._id = id_;
                this._name = name_;
                initializeKeyedItem();
            }
            mixin KeyedItem!();
        }
        mixin KeyedCollection!(Distro);
    }
    Distros GetFromDB()
    {
        auto distros = new Distros();
        distros.add(
            [
                distros.new Distro(1, "Fedora"),
                distros.new Distro(2, "Ubuntu"),
                distros.new Distro(3, "Linux Mint"),
                distros.new Distro(4, "Debian"),
                distros.new Distro(5, "CentOS")
            ]);
        return distros;
    }

    auto distros = GetFromDB();
    assert(distros.length == 5);
    assert(distros[1].name == "Fedora");
    distros[3].name = "Mint";
    assert(distros[3].name == "Mint");
    assert(distros[3].outer is distros);
}
