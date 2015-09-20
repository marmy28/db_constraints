/**
Source:
    http://zetcode.com/db/sqlite/constraints/
 */
module test.authors;

import db_constraints;

version(unittest)
class Author
{
private:
    int _AuthorId;
    string _Name;
public:
    @PrimaryKeyColumn
    int AuthorId() @property
    {
        return _AuthorId;
    }
    void AuthorId(int value) @property
    {
        setter(_AuthorId, value);
    }
    string Name() @property const
    {
        return _Name;
    }
    void Name(string value) @property
    {
        setter(_Name, value);
    }
    this(int AuthorId_, string Name_)
    {
        this._AuthorId = AuthorId_;
        this._Name = Name_;
        initializeKeyedItem();
    }
    Author dup()
    {
        return new Author(this._AuthorId, this._Name);
    }

    override string toString()
    {
        return "AuthorId: " ~ this._AuthorId.to!string() ~ " Name: " ~ this._Name;
    }
    mixin KeyedItem!(typeof(this));
}

version(unittest)
class Authors : BaseKeyedCollection!(Author)
{
public:
    this(Author[] items)
    {
        super(items);
    }
    this(Author item)
    {
        super(item);
    }
    static Authors GetFromDB()
    {
        return new Authors([
                            new Author(1, "Jane Austen"),
                            new Author(2, "Leo Tolstoy"),
                            new Author(3, "Joseph Heller"),
                            new Author(4, "Charles Dickens")
                            ]);
    }
    auto byValue() inout
    {
        return this._items.byValue();
    }
}
