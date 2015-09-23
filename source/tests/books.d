/**
Source:
    http://zetcode.com/db/sqlite/constraints/
 */
module test.books;

version(unittest)
{
    import db_constraints;
    import test.authors;
}

version(unittest)
class Book
{
private:
    int _BookId;
    string _Title;
    int _AuthorId;
public:
    @PrimaryKeyColumn
    int BookId() @property
    {
        return _BookId;
    }
    void BookId(int value) @property
    {
        setter(_BookId, value);
    }
    string Title() @property
    {
        return _Title;
    }
    void Title(string value) @property
    {
        setter(_Title, value);
    }
    Author.PrimaryKey AuthorForeignKey() @property
    {
        auto i = Author.PrimaryKey();
        i.AuthorId = this.AuthorId;
        return i;
    }
    void AuthorForeignKey(Author.PrimaryKey value) @property
    {
        if (value != this.AuthorForeignKey)
        {
            this.AuthorId = value.AuthorId;
        }
    }
    int AuthorId() @property
    {
        return _AuthorId;
    }
    void AuthorId(int value) @property
    {
        setter(_AuthorId, value);
    }
    this(int BookId_, string Title_, int AuthorId_)
    {
        this._BookId = BookId_;
        this._Title = Title_;
        this._AuthorId = AuthorId_;
        initializeKeyedItem();
    }
    Book dup()
    {
        return new Book(this._BookId, this._Title, this._AuthorId);
    }

    override string toString()
    {
        return "BookId: " ~ this._BookId.to!string() ~ " Title: " ~ this._Title ~ "AuthorId: " ~ this._AuthorId.to!string();
    }
    mixin KeyedItem!(typeof(this));

}

version(unittest)
class Books : BaseKeyedCollection!(Book)
{
private:
    import std.algorithm : filter, each;
    import std.range : takeOne;
    import std.parallelism;

    Authors *_authors;
    void checkForeignKeys()
    {
        if (this._authors !is null)
        {
            //foreach(ref item; taskPool.parallel(this.byValue))
            foreach(ref item; this.values)
            {
                if (!this._authors.contains(item.AuthorForeignKey))
                {
                    throw new ForeignKeyException("No author foreign key");
                }
            }
        }
    }
    bool _changedKey = false;
    Authors.key_type _changedAuthor;
public:
    void foreignKeyChanged(string propertyName, Authors.key_type item_key)
    {
        if (propertyName == "AuthorId")
        {
            _changedAuthor = item_key;
            _changedKey = true;
        }
        else if (propertyName == "key")
        {
            this.byValue.filter!(a => a.AuthorForeignKey == this._changedAuthor)
                .each!(a => a.AuthorForeignKey = item_key);
        }
        std.stdio.writeln(propertyName ~ " AuthorId: " ~ item_key.AuthorId.to!string);
    }
    void associateParent(ref Authors authors_)
    {
        if (this._authors is null)
        {
            _authors = &authors_;
            this._authors.collectionChanged.connect(&foreignKeyChanged);
        }
        checkForeignKeys();
    }
    this(Book[] items)
    {
        super(items);
    }
    this(Book item)
    {
        super(item);
    }

    static Books GetFromDB()
    {
        return new Books([
                          new Book(1, "Emma", 1),
                          new Book(2, "War and Peace", 2),
                          new Book(3, "Catch XII", 3),
                          new Book(4, "David Copperfield", 4),
                          new Book(5, "Good as Gold", 3),
                          new Book(6, "Anna Karenia", 2)
                          ]);
    }
}
unittest
{
    auto authors = Authors.GetFromDB();
    auto books = Books.GetFromDB();
    import std.exception : assertNotThrown, assertThrown;
    assertNotThrown!ForeignKeyException(books.associateParent(authors));
    assert(books._authors.contains(1) && !books._authors.contains(5));
    authors[1].AuthorId = 5;
    assert(!books._authors.contains(1) && books._authors.contains(5));
    // this should actually not be a thrown but should update or do something
    assertNotThrown!ForeignKeyException(books.checkForeignKeys());
}
