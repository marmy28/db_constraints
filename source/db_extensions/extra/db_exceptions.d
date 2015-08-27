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
    next = references the exception that was being handled when
    this one was generated
 */
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super("Primary key violation. " ~ msg, file, line, next);
    }
}

/**
Inherits from Exception. This is thrown whenever
there is a unique constraint violation.
 */
class UniqueConstraintException : Exception
{
/**
Params:
    msg = the message thrown with the unique constraint violation.
    next = references the exception that was being handled when
    this one was generated
 */
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super("Unique constraint violation. " ~ msg, file, line, next);
    }
}
