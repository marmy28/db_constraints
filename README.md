# db_extensions

[![Build Status](https://travis-ci.org/marmy28/db_extensions.svg)](https://travis-ci.org/marmy28/db_extensions)

## Generating documentation

Ddoc:

    dub --build=docs
    cd docs
    for i in ./*.html; do mv "$i" "${i%\.html}.md"; done

## Running tests

    dub test
