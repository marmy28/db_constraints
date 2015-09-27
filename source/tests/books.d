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
    int _AuthorId;
public:
    @PrimaryKeyColumn @NotNull
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
    mixin KeyedItem!();

}

version(unittest)
class Books : BaseKeyedCollection!(Book)
{
private:
    import std.algorithm : filter, each, canFind;

    auto BookFK = ForeignKeyConstraint!(
    "fk_Books_Authors_AuthorId",
    ["AuthorId"],
    "Authors",
    ["AuthorId"],
    Rule.cascade,
    Rule.cascade)();

    Authors *_authors;

    void checkForeignKeys()
    {
        if (this._authors !is null)
        {
            this.byValue.each!(
                (Book a) =>
                {
                    auto i = Authors.key_type.init;
                    // I will need to see if there are any null values if setNull is an action
                    i.AuthorId = a.AuthorId;
                    enforceEx!ForeignKeyException(this._authors.contains(i), "No author foreign key");
                }());
        }
    }
    Authors.key_type _changedAuthor;
public:
    void foreignKeyChanged(string propertyName, Authors.key_type item_key)
    {
        if (canFind(BookFK.referencedColumnNames, propertyName))
        {
            _changedAuthor = item_key;
        }
        else if (propertyName == "key")
        {
            auto changedAuthorFK = this.byValue.filter!(
                (Book a) =>
                {
                    auto i = Authors.key_type.init;
                    i.AuthorId = a.AuthorId;
                    return (i == this._changedAuthor);
                }());
            final switch (BookFK.updateRule) with (Rule)
            {
            case noAction:
                version(noActionIsRestrict) goto case restrict;
                else break;
            case restrict:
                if (!changedAuthorFK.empty)
                {
                    throw new ForeignKeyException("Author foreign key violation.");
                }
                break;
            case setNull:
                static if (__traits(compiles,
                                    (Book a)
                                    {
                                        a.AuthorId = null;
                                    }))
                {
                    changedAuthorFK.each!(
                        (Book a) =>
                        {
                            a.AuthorId = null;
                        }());
                    break;
                }
                else
                {
                    throw new ForeignKeyException("Cannot use ForeignKeyActions.setNull " ~
                                                  "when the member cannot be set to null.");
                }
            case setDefault:
                changedAuthorFK.each!(
                    (Book a) =>
                    {
                        a.AuthorId = typeof(a.AuthorId).init;
                    }());
                break;
            case cascade:
                changedAuthorFK.each!(
                    (Book a) =>
                    {
                        a.AuthorId = item_key.AuthorId;
                    }());
                break;
            }
        }
        else if (propertyName == "remove")
        {
            auto removedAuthorFK = this.byValue.filter!(
                (Book a) =>
                {
                    auto i = Authors.key_type.init;
                    i.AuthorId = a.AuthorId;
                    return (i == item_key);
                }());
            final switch (BookFK.deleteRule) with (Rule)
            {
            case noAction:
                version(noActionIsRestrict) goto case restrict;
                else break;
            case restrict:
                if (!removedAuthorFK.empty)
                {
                    throw new ForeignKeyException("Author foreign key violation.");
                }
                break;
            case setNull:
                static if (__traits(compiles,
                                    (Book a)
                                    {
                                        a.AuthorId = null;
                                    }))
                {
                    removedAuthorFK.each!(
                        (Book a) =>
                        {
                            a.AuthorId = null;
                        }());
                    break;
                }
                else
                {
                    throw new ForeignKeyException("Cannot use ForeignKeyActions.setNull " ~
                                                  "when the member cannot be set to null.");
                }
            case setDefault:
                removedAuthorFK.each!(
                    (Book a) =>
                    {
                        a.AuthorId = typeof(a.AuthorId).init;
                    }());
                break;
            case cascade:
                removedAuthorFK.each!(
                    (Book a) =>
                    {
                        this.remove(a.key);
                    }());
                break;
            }
        }
    }
    void authors(ref Authors authors_) @property
    {
        this._authors = &authors_;
        this._authors.collectionChanged.connect(&foreignKeyChanged);
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
