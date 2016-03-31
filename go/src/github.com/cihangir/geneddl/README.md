[![GoDoc](https://godoc.org/github.com/cihangir/geneddl?status.svg)](https://godoc.org/github.com/cihangir/geneddl)
[![Build Status](https://travis-ci.org/cihangir/geneddl.svg)](https://travis-ci.org/cihangir/geneddl)

# geneddl

Tired of bootstrapping?

Json-schema based SQL generation with Go (golang).

## Why Code Generation?

Whenever a bootstrap is required for a project we are hustling with creating the
required folder, files, databases, roles/users schemas, sequences, tables,
constraints, extensions types etc...

This package aims to ease that pain

## What is JSON-Schema?

JSON Schema specifies a JSON-based format to define the structure of your data
for various cases, like validation, documentation, and interaction control.  A
JSON Schema provides a contract for the JSON data required by a given
application, and how that data can be modified.

TLDR: here is an example [twitter.json](https://github.com/cihangir/gene/blob/master/example/twitter.json)

## Where is sample output?

Right here [twitter/db](https://github.com/cihangir/gene/blob/master/example/twitter/db)
