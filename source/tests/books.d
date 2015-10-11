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

    import std.exception : assertNotThrown;
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
    static assert(hasDefault!(Book, "AuthorId"));
    assert(hasDefault!(Book, "AuthorId"));
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
    static assert(hasForeignKeys!(Book));
    assert(hasForeignKeys!(Book));
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
`private Authors *_authors;
private Authors.key_type _changedAuthorsRow;
final @property void authors(ref Authors authors_)
{
    this.authors = null;
    this._authors = &authors_;
    this._authors.collectionChanged.connect(&fk_Books_Authors_AuthorId_Changed);
    checkForeignKeys();
}
final @property void authors(typeof(null) n)
{
    if (this._authors !is null)
    {
        this._authors.collectionChanged.disconnect(&fk_Books_Authors_AuthorId_Changed);
    this._authors = null;
    }
}
`;
    static assert(createForeignKeyProperties!(Book) == fkproperties);
    assert(createForeignKeyProperties!(Book) == fkproperties);
}

unittest
{
    enum fkexceptions =
`if (this._authors !is null)
{
    Authors.key_type i;
    if(a.fk_Books_Authors_AuthorId_key(i))
    {
        enforceEx!ForeignKeyException(this._authors.contains(i), "fk_Books_Authors_AuthorId violation.");
    }
}
`;
    static assert(createForeignKeyCheckExceptions!(Book) == fkexceptions);
    assert(createForeignKeyCheckExceptions!(Book) == fkexceptions);
}

unittest
{
    enum fkChanged =
        `Rule fk_Books_Authors_AuthorId_UpdateRule = Rule.cascade;
Rule fk_Books_Authors_AuthorId_DeleteRule = Rule.cascade;
void fk_Books_Authors_AuthorId_Changed(string propertyName, Authors.key_type item_key)
{
    if (canFind(["AuthorId"], propertyName))
    {
        this._changedAuthorsRow = item_key;
    }
    else if (propertyName == "key")
    {
        auto changedAuthors = this.byValue.filter!(
            (Book a) =>
            {
                Authors.key_type i;
                return (a.fk_Books_Authors_AuthorId_key(i) ? i == this._changedAuthorsRow : false);
            }());
        final switch (fk_Books_Authors_AuthorId_UpdateRule) with (Rule)
        {
        case noAction:
            break;
        case restrict:
            if (!changedAuthors.empty)
                throw new ForeignKeyException("fk_Books_Authors_AuthorId violation.");
            break;
        case setNull:
        static if (__traits(compiles,
                            (Book a)
                            {
                                a.AuthorId = null;
                            }))
            {
                changedAuthors.each!(
                    (Book a) =>
                    {
                        a.AuthorId = null;
                    }());
                break;
            }
            else
            {
                throw new ForeignKeyException("fk_Books_Authors_AuthorId. Cannot use Rule.setNull when the member cannot be set to null.");
            }
        case setDefault:
            changedAuthors.each!(
                (Book a) =>
                {
                    static if (hasDefault!(Book, "AuthorId"))                    {
                        a.AuthorId = GetDefault!(Book, "AuthorId");
                    }
                    else
                    {
                        a.AuthorId = typeof(a.AuthorId).init;
                    }
                }());
            break;
        case cascade:
            changedAuthors.each!(
                (Book a) =>
                {
                    a.AuthorId = item_key.AuthorId;
                }());
            break;
        }
    }
    else if (propertyName == "remove")
    {
        auto removedAuthors = this.byValue.filter!(
            (Book a) =>
            {
                Authors.key_type i;
                return (a.fk_Books_Authors_AuthorId_key(i) ? i == item_key : false);
            }());
        final switch (fk_Books_Authors_AuthorId_DeleteRule) with (Rule)
        {
        case noAction:
            break;
        case restrict:
            if (!removedAuthors.empty)
                throw new ForeignKeyException("fk_Books_Authors_AuthorId violation.");
            break;
        case setNull:
        static if (__traits(compiles,
                            (Book a)
                            {
                                a.AuthorId = null;
                            }))
            {
                removedAuthors.each!(
                    (Book a) =>
                    {
                        a.AuthorId = null;
                    }());
                break;
            }
            else
            {
                throw new ForeignKeyException("fk_Books_Authors_AuthorId. Cannot use Rule.setNull when the member cannot be set to null.");
            }
        case setDefault:
            removedAuthors.each!(
                (Book a) =>
                {
                    static if (hasDefault!(Book, "AuthorId"))                    {
                        a.AuthorId = GetDefault!(Book, "AuthorId");
                    }
                    else
                    {
                        a.AuthorId = typeof(a.AuthorId).init;
                    }
                }());
            break;
        case cascade:
            removedAuthors.each!(
                (Book a) =>
                {
                    this.remove(a.key);
                }());
            break;
        }
    }
}
`;
    static assert(createForeignKeyChanged!(Book) == fkChanged);
    assert(createForeignKeyChanged!(Book) == fkChanged);
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

    static assert(createForeignKeyPropertyConverter!(Book) == fkproperties, createForeignKeyPropertyConverter!(Book));
    assert(createForeignKeyPropertyConverter!(Book) == fkproperties, createForeignKeyPropertyConverter!(Book));
}

unittest
{
    auto authors = Authors.GetFromDB();
    auto books = Books.GetFromDB();

    books.authors = authors;
    books.fk_Books_Authors_AuthorId_UpdateRule = Rule.restrict;
    books.fk_Books_Authors_AuthorId_DeleteRule = Rule.restrict;

    import std.exception : assertThrown;

    assertThrown!ForeignKeyException(authors.remove(3));

    assert(!authors.contains(18));
    assertThrown!ForeignKeyException(books[1].AuthorId = 18);
}
