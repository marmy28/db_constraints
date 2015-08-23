module db_extensions.extra.db_exceptions;

/**
Inherits from Exception. This is thrown whenever
there is a primary key violation.
 */
class PrimaryKeyException : Exception
{
/**
Params:
    msg = the message thrown with the primary key violation.
 */
    this(string msg)
    {
        super("Primary key violation. " ~ msg);
    }
}
