# db_constraints

[![Dub](https://img.shields.io/badge/dub-code.dlang.org-FF4081.svg)](http://code.dlang.org/packages/db_constraints)

[![Build Status](https://travis-ci.org/marmy28/db_constraints.svg)](https://travis-ci.org/marmy28/db_constraints)

[![Coverage Status](https://coveralls.io/repos/marmy28/db_constraints/badge.svg?branch=master&service=github)](https://coveralls.io/github/marmy28/db_constraints?branch=master)

## Includes

 + [UniqueConstraintColumn](https://github.com/marmy28/db_constraints/wiki/constraints#UniqueConstraintColumn)
 + [PrimaryKeyColumn](https://github.com/marmy28/db_constraints/wiki/constraints#PrimaryKeyColumn)
 + [CheckConstraint](https://github.com/marmy28/db_constraints/wiki/constraints#CheckConstraint)
 + [NotNull](https://github.com/marmy28/db_constraints/wiki/constraints#NotNull)
 + [SetConstraint](https://github.com/marmy28/db_constraints/wiki/constraints#SetConstraint)
 + [EnumConstraint](https://github.com/marmy28/db_constraints/wiki/constraints#EnumConstraint)
 + [ForeignKeyConstraint](https://github.com/marmy28/db_constraints/wiki/constraints#ForeignKeyConstraint)
 + [Github markdown ddoc!](https://github.com/marmy28/db_constraints/blob/master/github.ddoc)

## Generating documentation

Ddoc:

    dub -b docs

## Running tests

    dub test

If you want the coverage analysis too use:

    dub test -b unittest-cov

## Documentation/Tutorials

Please, refer to [the wiki](https://github.com/marmy28/db_constraints/wiki) for code documentation and tutorial on how to use this package.

## Contribution

Contributions are welcome. Feel free to fork and pull request!

## Limitations

 + The getter and setter should have the same name. The private member should have the same name as the getter and setter but starting with an underscore. Look at any of the examples on [the wiki](https://github.com/marmy28/db_constraints/wiki/examples_at_zetcode) if this wording does not make sense.
 + You may only foreign key to the referenced class' clustered index. If you foreign key to id's and mark all your id's as primary keys then you do not need to worry about this.
 + Cannot use structs until std.signals can work with structs.
 
## Todo
 
 + [X] Finish moving example names.
 + [ ] Write enum example.
 + [ ] Fix wiki Limitations.
 + [ ] Fix wiki examples_at_zetcode.md.
 + [ ] Put out next tag.
 + [ ] Add versioning comments to code.
