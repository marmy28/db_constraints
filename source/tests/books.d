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
        return "BookId: " ~ this._BookId.to!string() ~ " Title: " ~ this._Title ~ "AuthorId: " ~ this._AuthorId.to!string();
    }
    mixin KeyedItem!();

}

version(unittest)
class Books
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

    void checkForeignKeys()
    {
        this.byValue.each!(
            (Book a) =>
            {
                if (this._authors !is null)
                {
                    auto i = Authors.key_type.init;
                    static if (is(typeof(i.AuthorId) == typeof(a.AuthorId)))
                    {
                        i.AuthorId = a.AuthorId;
                        enforceEx!ForeignKeyException(this._authors.contains(i), "No author foreign key");
                    }
                    else static if (__traits(compiles,
                                             (Book b)
                                             {
                                                 bool j = b.AuthorId.isNull;
                                             }))
                    {
                        if (!a.AuthorId.isNull)
                        {
                            i.AuthorId = a.AuthorId;
                            enforceEx!ForeignKeyException(this._authors.contains(i), "No author foreign key");
                        }
                    }
                    else
                    {
                        static assert(0, "Foreign key types are not the same and the child column is not a nullable.");
                    }
                }
            }());
    }
public:
    Rule onUpdate = BookFK.updateRule;
    Rule onDelete = BookFK.deleteRule;
    mixin KeyedCollection!(Book);
    void foreignKeyChanged(string propertyName, Authors.key_type item_key)
    {
        if (canFind(BookFK.referencedColumnNames, propertyName))
        {
            _changedAuthorsRow = item_key;
        }
        else if (propertyName == "key")
        {
            auto changedAuthorFK = this.byValue.filter!(
                (Book a) =>
                {
                    auto i = Authors.key_type.init;
                    static if (is(typeof(i.AuthorId) == typeof(a.AuthorId)))
                    {
                        i.AuthorId = a.AuthorId;
                        return (i == this._changedAuthorsRow);
                    }
                    else static if (__traits(compiles,
                                             (Book b)
                                             {
                                                 bool j = b.AuthorId.isNull;
                                             }))
                    {
                        if(!a.AuthorId.isNull)
                        {
                            i.AuthorId = a.AuthorId;
                            return (i == this._changedAuthorsRow);
                        }
                        else
                        {
                            return false;
                        }
                    }
                    else
                    {
                        static assert(0, "Foreign key types are not the same and the child column is not a nullable.");
                    }
                }());
            final switch (onUpdate) with (Rule)
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
                    static if (is(typeof(i.AuthorId) == typeof(a.AuthorId)))
                    {
                        i.AuthorId = a.AuthorId;
                        return (i == item_key);
                    }
                    else static if (__traits(compiles,
                                             (Book b)
                                             {
                                                 bool j = b.AuthorId.isNull;
                                             }))
                    {
                        if(!a.AuthorId.isNull)
                        {
                            i.AuthorId = a.AuthorId;
                            return (i == item_key);
                        }
                        else
                        {
                            return false;
                        }
                    }
                    else
                    {
                        static assert(0, "Foreign key types are not the same and the child column is not a nullable.");
                    }
                }());
            final switch (onDelete) with (Rule)
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
    pragma(msg, GetForeignKeys!(Book));
    pragma(msg, GetForeignKeyRefTable!(Book));
    static assert(HasForeignKeys!(Book));
}

unittest
{
    auto authors = Authors.GetFromDB();
    auto books = Books.GetFromDB();

    books.authors = authors;
    books.onDelete = Rule.setNull;
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
    books.onUpdate = Rule.setNull;
    authors[5].AuthorId = 1;
    i = 0;
    foreach(book; books)
    {
        if (book.AuthorId.isNull)
        {
            ++i;
        }
    }
    assert(i == 3, i.to!string);
}
