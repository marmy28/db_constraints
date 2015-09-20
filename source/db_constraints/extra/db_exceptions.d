module db_constraints.extra.db_exceptions;

/**
Inherits from Exception. This is thrown whenever
there is a unique constraint violation.
 */
class UniqueConstraintException : Exception
{
/**
Params:
    msg = the message thrown with the unique constraint violation
    file = the file where the exception occurred
    line = the line number where the exception occurred
    next = references the exception that was being handled when this one was generated
 */
    this(string msg, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null)
    {
        super("Unique constraint violation. " ~ msg, file, line, next);
    }
}
/**
Inherits from Exception. This is thrown whenever
there is an exception dealing with the keyed items.
 */
class KeyedException : Exception
{
/**
Params:
    msg = the message thrown
    file = the file where the exception occurred
    line = the line number where the exception occurred
    next = references the exception that was being handled when this one was generated
 */
    this(string msg, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

/**
Inherits from Exception. This is thrown whenever
there is a check constraint violation.
 */
class CheckConstraintException : Exception
{
/**
Params:
    msg = the message thrown with the check constraint violation
    file = the file where the exception occurred
    line = the line number where the exception occurred
    next = references the exception that was being handled when this one was generated
 */
    this(string msg, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null)
    {
        super("Check constraint violation. " ~ msg, file, line, next);
    }
}
