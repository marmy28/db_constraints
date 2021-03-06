# test.examples_foreign_key


The following examples come from
[http://zetcode.com/db/sqlite/constraints/](http://zetcode.com/db/sqlite/constraints/).
Even though it is a SQLite tutorial the point is to show how to use this package
which does not have to be just SQLite.

***
<a name="BlankClassSoDocsWillBeGenerated" href="#BlankClassSoDocsWillBeGenerated"></a>
```d
class BlankClassSoDocsWillBeGenerated;

```

**Examples:**

This example is for the FOREIGN KEY constraints. The tables
in SQL can be created by
```sql
CREATE TABLE Authors
(
    AuthorId INTEGER NOT NULL PRIMARY KEY,
    Name TEXT
);


CREATE TABLE Books
(
    BookId INTEGER NOT NULL PRIMARY KEY,
    Title TEXT,
    AuthorId INTEGER,
    FOREIGN KEY (AuthorId) REFERENCES Authors(AuthorId)
);


```


The Books table now must have values in Books.AuthorId that are in
Authors.AuthorId. By default if Authors deletes or updates its AuthorId
and Books references the AuthorId, an exception is thrown. If you would
like Books to cascade the effects instead you would create the Books table like
```sql
CREATE TABLE Books
(
    BookId INTEGER NOT NULL PRIMARY KEY,
    Title TEXT,
    AuthorId INTEGER,
    FOREIGN KEY (AuthorId) REFERENCES Authors(AuthorId)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


```


This package can do any of the update or delete rules.
For more rules information look at [Rule](https://github.com/marmy28/db_constraints/wiki/constraints#Rule).


Below I will create the classes. I will use the cascaded Books for this example.

```d

import db_constraints;

class Author
{
    private int _AuthorId;
    @PrimaryKeyColumn @NotNull
    @property int AuthorId()
    {
        return _AuthorId;
    }
    @property void AuthorId(int value)
    {
        setter(_AuthorId, value);
    }
    private string _Name;
    @property string Name()
    {
        return _Name;
    }
    @property void Name(string value)
    {
        setter(_Name, value);
    }
    this(int AuthorId_, string Name_)
    {
        this._AuthorId = AuthorId_;
        this._Name = Name_;
        initializeKeyedItem();
    }

    // we must define dup() since we are going
    // to change AuthorId which is our implied
    // clustered index
    Author dup()
    {
        return new Author(this._AuthorId, this._Name);
    }

    mixin KeyedItem!();
}
class Authors
{
    mixin KeyedCollection!(Author);
}

// adding in this function so we can get multiple
// author records at once
Authors GetAuthorsFromDB()
{
    return new Authors([
                       new Author(1, "Jane Austen"),
                       new Author(2, "Leo Tolstoy"),
                       new Author(3, "Joseph Heller"),
                       new Author(4, "Charles Dickens")
                       ]);
}


// we could put Books in a different file
// to do that you would just need to import the file where Authors is.

// attach the foreign key constraint attribute to the singular class
@ForeignKeyConstraint!(
    ["AuthorId"], /* Book column */
    "Authors", /* referenced table which is Authors in this case */
    ["AuthorId"], /* referenced column which is Authors.AuthorId */
    Rule.cascade, /* what to do when we update Authors.AuthorId */
    Rule.cascade) /* what to do when we delete Authors.AuthorId */
class Book
{
    private int _BookId;
    @PrimaryKeyColumn @NotNull
    @property int BookId()
    {
        return _BookId;
    }
    @property void BookId(int value)
    {
        setter(_BookId, value);
    }
    private string _Title;
    @property string Title()
    {
        return _Title;
    }
    @property void Title(string value)
    {
        setter(_Title, value);
    }
    private int _AuthorId;
    @property int AuthorId()
    {
        return _AuthorId;
    }
    @property void AuthorId(int value)
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

    mixin KeyedItem!();
}

class Books
{
    mixin KeyedCollection!(Book);
}
Books GetBooksFromDB()
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


// we will get both collections
// and then associate authors to books

// ON UPDATE CASCADE
{
    auto authors = GetAuthorsFromDB();
    auto books = GetBooksFromDB();

    // when we associate authors to books
    // there should be no exceptions since
    // we are starting with correct data
    import std.exception : assertNotThrown, assertThrown;
    assertNotThrown!ForeignKeyException(books.authors = authors);
    // books.authors is a write-only property made by
    // mixin KeyedCollection!(Book);
    // you can also set books.authors = null when you want to
    // remove the association

    // if you recall from before we can use the primary key to
    // search our collections easily. In Books, Emma has BookId 1.
    assert(books[1].Title == "Emma");
    assert(books[1].BookId == 1);

    // Emma is written by Jane Austen and
    // in authors Jane Austen has AuthorId 1
    assert(authors[1].Name == "Jane Austen");
    assert(authors.contains(books[1].AuthorId));
    assert(authors[1].AuthorId == books[1].AuthorId);

    // lets say somehow we changed Jane Austen to have AuthorId 5
    // since we have on update cascade for books we would expect
    // Emma to get AuthorId 5
    authors[1].AuthorId = 5;
    // this will also change authors to no longer have key 1
    assert(authors.contains(5) && !authors.contains(1));
    // Emma still has BookId 1 since that did not change but
    // should have AuthorId 5
    assert(books[1].Title == "Emma");
    assert(books[1].AuthorId == 5);

    // We were able to change Jane Austen's AuthorId since we
    // defined dup in Author. We did not define dup in Books
    // which means if we change BookId we should expect a
    // KeyedException
    assertThrown!KeyedException(books[1].BookId = 7);

    // it is good but not necessary to set books.authors to null when you
    // leave scope just to disconnect signals and associations
    books.authors = null;
}

// ON DELETE CASCADE
{
    auto authors = GetAuthorsFromDB();
    auto books = GetBooksFromDB();
    books.authors = authors;

    // we have 4 authors
    assert(authors.length == 4);
    // and 6 books
    assert(books.length == 6);

    import std.algorithm : count;
    // there are two books that have author id 3
    auto booksWithAuthorId3 =
        books.byValue.count!((a, b) => a.AuthorId == b)(3);

    assert(booksWithAuthorId3 == 2);

    // this means if we delete AuthorId 3 from authors and
    // we have on delete cascade for books we should expect
    // books to have length 4 and authors to have length 3
    authors.remove(3);
    assert(authors.length == 3);
    assert(books.length == 4);

    booksWithAuthorId3 = books.byValue.count!((a, b) => a.AuthorId == b)(3);
    assert(booksWithAuthorId3 == 0);

    books.authors = null;
}

// ON DELETE RESTRICT
{
    import std.exception : assertThrown, assertNotThrown;
    auto authors = GetAuthorsFromDB();
    auto books = GetBooksFromDB();
    books.authors = authors;

    // you can change the on update and on delete rule for your foreign key
    // by using the foreign key name and _UpdateRule or _DeleteRule...we
    // did not name ours so it got the default fk_Book_Authors

    // lets say we want to restrict authors deletion now
    books.fk_Book_Authors_DeleteRule = Rule.restrict;

    // since we have 2 records in books that reference AuthorId 3 we should
    // get an exception when deleting AuthorId 3 from authors
    assertThrown!ForeignKeyException(authors.remove(3));

    // now we can unreference our table and remove 3 without errors
    books.authors = null;
    assertNotThrown!ForeignKeyException(authors.remove(3));

    // but now when we try to re-associate we will get an exception
    assertThrown!ForeignKeyException(books.authors = authors);
}

```




Copyright :copyright:  | Page generated by [Ddoc](http://dlang.org/ddoc.html) on Mon Mar  7 19:21:14 2016

