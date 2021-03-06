/**
DB Idea Source:
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
    @PrimaryKeyColumn @NotNull
    @property void AuthorId(int value)
    {
        setter(_AuthorId, value);
    }
    @UniqueConstraintColumn!"uc_Author"
    @property string Name()
    {
        return _Name;
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

    override bool opEquals(Object o) const pure nothrow @nogc
    {
        auto rhs = cast(immutable Author)o;
        return (rhs !is null && this.uc_Author_key == rhs.uc_Author_key);
    }
    mixin KeyedItem!();
}

version(unittest)
class Authors : BaseKeyedCollection!(Author)
{
public:
    this(Author[] items)
    {
        super(items);
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
}

unittest
{
    auto authors = Authors.GetFromDB();
    // using integers since AuthorId is the clustered index
    for(int i = 0; i < authors.length; ++i)
    {
        for(int j = i + 1; j < authors.length; ++j)
        {
            assert(authors[i + 1] != authors[j + 1]);
        }
    }
}
