logging
=======

Simple logging package in Go.

[![GoDoc](https://godoc.org/github.com/koding/logging?status.svg)](https://godoc.org/github.com/koding/logging)
[![Build Status](https://travis-ci.org/koding/logging.svg)](https://travis-ci.org/koding/logging)


Install
-------

```sh
$ go get github.com/koding/logging
```


Features
--------

* Log levels (DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL)
* Different colored output for different levels (can be disabled)
* No global state in package
* Customizable logging handlers
* Customizable formatters
* Log to multiple backends concurrently
* Context based (inherited) loggers


Example Usage
-------------

See [https://github.com/koding/logging/blob/master/example/example.go](https://github.com/koding/logging/blob/master/example/example.go)
