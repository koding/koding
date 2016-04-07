[![GoDoc](https://godoc.org/github.com/cihangir/gene?status.svg)](https://godoc.org/github.com/cihangir/gene)
[![Build Status](https://travis-ci.org/cihangir/gene.svg)](https://travis-ci.org/cihangir/gene)

# gene

Tired of bootstrapping?

Json-schema based code generation with Go (golang).

## Why Code Generation?

Whenever a bootstrap is required for a project we are hustling with creating the
required folder, files, configs, api function, endpoints, clients, tests etc...

This package aims to ease that pain

## What is JSON-Schema?

JSON Schema specifies a JSON-based format to define the structure of your data
for various cases, like validation, documentation, and interaction control.  A
JSON Schema provides a contract for the JSON data required by a given
application, and how that data can be modified.

TLDR: here is an example [twitter.json](https://github.com/cihangir/gene/blob/master/example/tinder.json)

## Features

#### Models
* Creating Models from json-schema definitions
* Creating Validations for Models from json-schema definitions
* Creating Constants for Model properties from json-schema definitions
* Creating JSON Tags for Model properties from json-schema definitions
* Adding golint-ed Documentations to the Models, Functions and Exported Variables
* Creating Constructor Functions for Models with their default values from json-schema definitions

#### SQL
* Creating Insert, Update, Delete, Select sql.DB.* compatible plain SQL statements without any reflection

#### Tests
* Providing simple Assert, Ok, Equals test functions for the app

#### Workers

#### API
* Creating rpc api endpoints for Create, Update, Select, Delete operations for every definition in json-schema

#### Client
* Creating Client code for communication with your endpoints

#### CMD
* Creating basic cli for the worker

#### Errors
* Creating idiomatic Go Errors for the api, validations etc.

#### Tests
* Creating tests for the generated api endpoints

## Install

Package itself is not go gettable, get the cli for generating your app
```
go install github.com/cihangir/gene/cmd/gene
```

## Usage

After having gene executable in your path
Pass schema flag for your base json-schema, and target as the existing path for your app

```
gene -schema ./example/tinder.json -target ./example/
```


For now, it is generating the following folder/file structure
```
./src/github.com/cihangir/gene/example
├── db
│   ├── 001-tinder_db_roles.sql
│   ├── 002-tinder_db_database.sql
│   └── tinder_schema
│       ├── 004-schema.sql
│       ├── 005-account-sequence.sql
│       ├── 005-facebook_friends-sequence.sql
│       ├── 005-facebook_profile-sequence.sql
│       ├── 005-profile-sequence.sql
│       ├── 006-account-types.sql
│       ├── 007-account-table.sql
│       ├── 007-facebook_friends-table.sql
│       ├── 007-facebook_profile-table.sql
│       ├── 007-profile-table.sql
│       ├── 008-account-constraints.sql
│       ├── 008-facebook_friends-constraints.sql
│       ├── 008-facebook_profile-constraints.sql
│       └── 008-profile-constraints.sql
├── dockerfiles
│   ├── account
│   │   └── Dockerfile
│   ├── facebookfriends
│   │   └── Dockerfile
│   ├── facebookprofile
│   │   └── Dockerfile
│   └── profile
│       └── Dockerfile
├── errors
│   ├── account.go
│   ├── facebookfriends.go
│   ├── facebookprofile.go
│   └── profile.go
├── models
│   ├── account.go
│   ├── account_rowscanner.go
│   ├── facebookfriends.go
│   ├── facebookfriends_rowscanner.go
│   ├── facebookprofile.go
│   ├── facebookprofile_rowscanner.go
│   ├── markasrequest.go
│   ├── profile.go
│   └── profile_rowscanner.go
└── workers
    ├── account
    │   ├── interface.go
    │   ├── service.go
    │   ├── transport_http_client.go
    │   ├── transport_http_semiotics.go
    │   └── transport_http_server.go
    ├── cmd
    │   └── account
    │       └── main.go
    ├── facebookfriends
    │   ├── interface.go
    │   ├── service.go
    │   ├── transport_http_client.go
    │   ├── transport_http_semiotics.go
    │   └── transport_http_server.go
    ├── facebookprofile
    │   ├── interface.go
    │   ├── service.go
    │   ├── transport_http_client.go
    │   ├── transport_http_semiotics.go
    │   └── transport_http_server.go
    ├── kitworker
    │   ├── client.go
    │   ├── instrumenting.go
    │   ├── server.go
    │   └── zipkin.go
    └── profile
        ├── interface.go
        ├── service.go
        ├── transport_http_client.go
        ├── transport_http_semiotics.go
        └── transport_http_server.go

17 directories, 58 files
```
