osin-mongo-storage
==================

[![Build Status](https://travis-ci.org/martint17r/osin-mongo-storage.svg?branch=master)](https://travis-ci.org/martint17r/osin-mongo-storage)

This package implements the storage interface for [OSIN](https://github.com/RangelReale/osin) with [MongoDB](http://www.mongodb.org/) using [mgo](http://labix.org/mgo).

[![baby-gopher](https://raw2.github.com/drnic/babygopher-site/gh-pages/images/babygopher-badge.png)](http://www.babygopher.org)

Docker
------
The shell scripts under bin/ build a docker image and execute the tests. Make sure that you can run docker without sudo.

Caveats
-------

All structs are serialized as is, i.e. no references are created or resolved.

Currently MongoDB >= 2.6 is required, on 2.4 the TestLoad* Tests fail, but I do not know why.


Examples
--------

See the examples subdirectory for integrating into OSIN.


License
-------
This package is made available under the [MIT License](http://github.com/martint17r/osin-mongo-storage/LICENSE)
