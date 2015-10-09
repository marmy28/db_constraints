/**
The db_exceptions module contains:
  $(TOC UniqueConstraintException)
  $(TOC KeyedException)
  $(TOC CheckConstraintException)
  $(TOC ForeignKeyException)

License: $(GPL2)

Authors: Matthew Armbruster

$(B Source:) $(SRC $(SRCFILENAME))

Copyright: 2015
 */
module db_constraints.db_exceptions;

/**
$(ANCHOR UniqueConstraintException)
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
$(ANCHOR KeyedException)
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
$(ANCHOR CheckConstraintException)
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

/**
$(ANCHOR ForeignKeyException)
Inherits from Exception. This is thrown whenever
there is an exception dealing with the foreign keys.
 */
class ForeignKeyException : Exception
{
/**
Params:
    msg = the message thrown with the foreign key
    file = the file where the exception occurred
    line = the line number where the exception occurred
    next = references the exception that was being handled when this one was generated
 */
    this(string msg, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null)
    {
        super("Foreign key exception. " ~ msg, file, line, next);
    }
}
