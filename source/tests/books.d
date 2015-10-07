/**
DB Idea Source:
    http://zetcode.com/db/sqlite/constraints/
 */
module test.books;

version(unittest)
{
    import db_constraints;
    import test.authors;
}

version(unittest)
@ForeignKeyConstraint!(
    "fk_Books_Authors_AuthorId",
    ["AuthorId"],
    "Authors",
    ["AuthorId"],
    Rule.cascade,
    Rule.cascade)
class Book
{
private:
    int _BookId;
    string _Title;
    Nullable!int _AuthorId;
public:
    @PrimaryKeyColumn @NotNull
    @property int BookId()
    {
        return _BookId;
    }
    @property void BookId(int value)
    {
        setter(_BookId, value);
    }
    @property string Title()
    {
        return _Title;
    }
    @property void Title(string value)
    {
        setter(_Title, value);
    }
    @Default!(2)
    @property Nullable!int AuthorId()
    {
        return _AuthorId;
    }
    @property void AuthorId(N)(N value)
        if (isNullable!(int , N))
    {
        setter(_AuthorId, value.to!(Nullable!int));
    }
    this(N)(int BookId_, string Title_, N AuthorId_)
        if (isNullable!(int, N))
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
        return "BookId: " ~ this._BookId.to!string() ~ " Title: " ~ this._Title ~ " AuthorId: " ~ this._AuthorId.to!string();
    }
    mixin KeyedItem!();

}

version(unittest)
class Books
{
    mixin KeyedCollection!(Book);

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
    assertNotThrown!ForeignKeyException(books.authors = authors);

    assert(books._authors.contains(1) && !books._authors.contains(5));
    authors[1].AuthorId = 5;
    assert(!books._authors.contains(1) && books._authors.contains(5));
    assertNotThrown!ForeignKeyException(books.checkForeignKeys());

    assert(authors.length == 4);
    assert(books.length == 6);
    authors.remove(3);
    assert(authors.length == 3);
    assert(books.length == 4);
}
unittest
{
    auto authors = Authors.GetFromDB();
    auto books = Books.GetFromDB();
    books.authors = authors;
    assert(authors.length == 4);
    assert(books._authors.length == 4);
    books.authors = null;
    assert(authors.length == 4);
    assert(books._authors is null);
}

unittest
{
    auto authors = Authors.GetFromDB();
    auto books = Books.GetFromDB();

    import std.algorithm : filter;
    import std.exception : assertNotThrown, assertThrown;
    assertNotThrown!ForeignKeyException(books.authors = authors);

    books.fk_Books_Authors_AuthorId_UpdateRule = Rule.setDefault;
    assert(authors.length == 4);
    assert(books.length == 6);
    int i = 0;
    foreach(book; books.byValue.filter!(a => a.AuthorId == 2))
        ++i;
    assert(i == 2);

    i = 0;
    foreach(book; books.byValue.filter!(a => a.AuthorId == 1))
        ++i;
    assert(i == 1);
    authors[1].AuthorId = 5;
    assert(authors.length == 4);
    assert(books.length == 6);
    i = 0;
    foreach(book; books.byValue.filter!(a => a.AuthorId == 2))
        ++i;
    assert(i == 3);

    books.fk_Books_Authors_AuthorId_DeleteRule = Rule.setDefault;
    authors.remove(3);
    assert(authors.length == 3);
    assert(books.length == 6);
    i = 0;
    foreach(book; books.byValue.filter!(a => a.AuthorId == 2))
        ++i;
    assert(i == 5);
}

unittest
{
    pragma(msg, GetForeignKeys!(Book));
    pragma(msg, GetForeignKeyRefTable!(Book));
    static assert(HasForeignKeys!(Book));
}

unittest
{
    auto authors = Authors.GetFromDB();
    auto books = Books.GetFromDB();

    books.authors = authors;
    books.fk_Books_Authors_AuthorId_DeleteRule = Rule.setNull;
    assert(authors.length == 4);
    assert(books.length == 6);
    authors.remove(3);
    assert(authors.length == 3);
    assert(books.length == 6);
    import std.exception : assertNotThrown;
    assertNotThrown!ForeignKeyException(books.checkForeignKeys());
    authors[1].AuthorId = 5;
    assert(authors.length == 3);
    assert(books.length == 6);
    int i = 0;
    foreach(book; books)
    {
        if (book.AuthorId.isNull)
        {
            ++i;
        }
    }
    assert(i == 2);
    books.fk_Books_Authors_AuthorId_UpdateRule = Rule.setNull;
    authors[5].AuthorId = 1;
    i = 0;
    foreach(book; books)
    {
        if (book.AuthorId.isNull)
        {
            ++i;
        }
    }
    assert(i == 3);
}

unittest
{
    enum fkproperties =
`final bool fk_Books_Authors_AuthorId_key(out Authors.key_type aKey)
{
    bool result;
    static if (
        is(typeof(aKey.AuthorId) == typeof(this.AuthorId))
        )
    {
        aKey.AuthorId = this.AuthorId;
        result = true;
    }
    else static if (__traits(compiles,
                             (Book b)
                             {
                                 if (b.AuthorId.isNull == true) { }
                             }))
    {
        if (
            !this.AuthorId.isNull
           )
        {
            aKey.AuthorId = this.AuthorId;
            result = true;
        }
        else
        {
            result = false;
        }
    }
    else
    {
        static assert(false, "Column type mismatch for fk_Books_Authors_AuthorId.");
    }
    return result;
}
`;

    static assert(ForeignKeyProperties!(Book) == fkproperties, ForeignKeyProperties!(Book));
}
