# db_constraints

[![Build Status](https://travis-ci.org/marmy28/db_constraints.svg)](https://travis-ci.org/marmy28/db_constraints)

[![Coverage Status](https://coveralls.io/repos/marmy28/db_constraints/badge.png?branch=master&service=github)](https://coveralls.io/github/marmy28/db_constraints?branch=master)


## Generating documentation

Ddoc:

    dub --build=docs

## Running tests

    dub test

If you want the coverage analysis too use:

    dub test -b unittest-cov

## Documentation (coming soon...)

Please, refer to [the wiki](https://github.com/marmy28/db_constraints/wiki) for code documentation and tutorial on how to use this package.

## Contribution

Contributions are welcome. Please let me know by email if you would like to help or have an idea on how to improve the design!

## To do
- [ ] Add in description for repo.
- [ ] Release package on dub
- [ ] Unittests for meta.d
- [ ] keyed collection takes iterable instead of just array
- [ ] remove extra functions from examples
- [ ] Write tutorial
  * [ ] Nested classes
  * [ ] Start with SQL CREATE TABLE and show how to transform to class
  * [ ] Add in special notes about limitations (private getter setter need to be same name, only foreign key to clustered index, etc.)

## Bugs
- [ ] Dealing with nulls for creating keyed item clustered key

## Future
- [ ] Add in struct functionality
- [ ] Auto increment (possibly)
