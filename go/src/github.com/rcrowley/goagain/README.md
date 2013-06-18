goagain
=======

Zero-downtime restarts in Go
----------------------------

Inspired by [Unicorn](http://unicorn.bogomips.org/), the `goagain` package provides primitives for bringing zero-downtime restarts to Go applications that accept connections from a [`net.TCPListener`](http://golang.org/pkg/net/#TCPListener).

Installation
------------

	go install github.com/rcrowley/goagain

Usage
-----

[`goagain-example.go`](https://github.com/rcrowley/goagain/blob/master/cmd/goagain-example/goagain-example.go) shows how it's done.
