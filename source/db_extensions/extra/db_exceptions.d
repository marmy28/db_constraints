module db_extensions.extra.db_exceptions;

class PrimaryKey : Exception
{
    this(string msg)
    {
        super("Duplicate primary key entry for " ~ msg);
    }
}
