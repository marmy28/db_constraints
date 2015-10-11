# db_constraints

[![Build Status](https://travis-ci.org/marmy28/db_constraints.svg)](https://travis-ci.org/marmy28/db_constraints)

[![Coverage Status](https://coveralls.io/repos/marmy28/db_constraints/badge.svg?branch=master&service=github)](https://coveralls.io/github/marmy28/db_constraints?branch=master)


## Generating documentation

Ddoc:

    dub -b docs

## Running tests

    dub test

If you want the coverage analysis too use:

    dub test -b unittest-cov

## Documentation

Please, refer to [the wiki](https://github.com/marmy28/db_constraints/wiki) for code documentation and tutorial on how to use this package.

## Contribution

Contributions are welcome. Feel free to fork and pull request!

## Limitations

 + The getter and setter should have the same name. The private member should have the same name as the getter and setter but starting with an underscore. Look at any of the examples on [the wiki](https://github.com/marmy28/db_constraints/wiki/examples_from_zetcode1) if this wording does not make sense.
 + You may only foreign key to the referenced class' clustered index. If you foreign key to id's and mark all your id's as primary keys then you do not need to worry about this.

## To do
- [ ] Add in description for repo.
- [ ] Release package on dub
- [ ] Unittests for meta.d
- [ ] Write tutorial
  * [ ] Nested classes
  * [ ] Finish examples with foreign keys
  * [ ] Advanced tutorial


## Future
- [ ] Add in struct functionality
- [ ] Auto increment (possibly)
