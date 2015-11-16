/**
The db_exceptions module contains:
  $(TOC UniqueConstraintException)
  $(TOC KeyedException)
  $(TOC CheckConstraintException)
  $(TOC ForeignKeyException)
  $(TOC ExclusionConstraintException)

License: $(GPL2)

Authors: Matthew Armbruster

$(B Source:) $(SRC $(SRCFILENAME))

Copyright: 2015
 */
module db_constraints.db_exceptions;

/**
Exception thrown on unique constraint violations.
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
Exception thrown on errors involved with keyed items.
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
Exception thrown on check constraint violations.
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
Exception thrown on foreign key violations.
 */
class ForeignKeyException : Exception
{
/**
Params:
    msg = the message thrown with the foreign key violation
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

/**
Exception thrown on exclusion constraint violations.

Version: \>=0.0.7
 */
class ExclusionConstraintException : Exception
{
/**
Params:
    msg = the message thrown with the exclusion constraint violation
    file = the file where the exception occurred
    line = the line number where the exception occurred
    next = references the exception that was being handled when this one was generated
 */
    this(string msg, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null)
    {
        super("Exclusion constraint violation. " ~ msg, file, line, next);
    }
}
