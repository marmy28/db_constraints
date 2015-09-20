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
    auto AuthorForeignKey() @property
    {
        auto i = Author.PrimaryKey();
        i.AuthorId = this.AuthorId;
        return i;
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
    // import std.algorithm : filter;
    // import std.range : takeOne;
    // import std.parallelism;

    // immutable(Authors) *_authors;
    // void assignForeign()
    // {
    //     if (this._authors !is null)
    //     {
    //         foreach(ref item; taskPool.parallel(this.byValue))
    //         {
    //             if (this._authors.contains(item.AuthorForeignKey))
    //             {
    //                 item.author = &(this._author[item.AuthorForeignKey]);
    //             }
    //             else
    //             {
    //                 std.stdio.writeln("No foreign key");
    //             }
    //             // auto author = this._authors.byValue.filter!(a => a.key == item.AuthorForeignKey).takeOne();
    //             // if (!author.empty)
    //             // {
    //             //     item.author = &(author.front());
    //             // }

    //         }
    //     }
    // }
public:
    // void associateParent(immutable(Authors) authors_)
    // {
    //     this._authors = &authors_;
    //     assignForeign();
    // }
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
