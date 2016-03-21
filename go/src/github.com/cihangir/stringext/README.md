[![GoDoc](https://godoc.org/github.com/cihangir/stringext?status.svg)](https://godoc.org/github.com/cihangir/stringext)
[![Build Status](https://travis-ci.org/cihangir/stringext.svg)](https://travis-ci.org/cihangir/stringext)


# stringext
Extension functions to Go's string package

--
    import "."

Package stringext adds extra power to the strings package with helper functions

## Usage

#### func  AsComment

```go
func AsComment(c string) string
```
AsComment formats the given string as if it is a Go Comment, breaks lines every
78 lines

#### func  Contains

```go
func Contains(n string, r []string) bool
```
Contains checks if the given string is in given string slice

#### func  Depunct

```go
func Depunct(ident string, initialCap bool) string
```
Depunct splits the given string with special chars and operates on them one by
one

#### func  DepunctWithInitialLower

```go
func DepunctWithInitialLower(ident string) string
```
DepunctWithInitialLower does special operations to the given string, while
operating lowercases the special words

#### func  DepunctWithInitialUpper

```go
func DepunctWithInitialUpper(ident string) string
```
DepunctWithInitialUpper does special operations to the given string, while
operating uppercases the special words

#### func  Equal

```go
func Equal(a, b string) bool
```
Equal check if given two strings are same, used in templates

#### func  JSONTag

```go
func JSONTag(n string, required bool) string
```
JSONTag generates json tag for given string, it is using the javascript concepts

eg: ID ->

    	becomes "id" if it is at the beginning
     	or
     becomes "Id" if it is in the middle of the string

#### func  Normalize

```go
func Normalize(s string) string
```
Normalize removes non a-z characters and uppercases the following character, all
characters followed by it will be lowercased if the word is one the acronymsi

#### func  Pointerize

```go
func Pointerize(ident string) string
```
Pointerize returns the first character of a given string as lowercased, this
method is intened to use as a function receiver generator

#### func  ToFieldName

```go
func ToFieldName(u string) string
```
ToFieldName handles field names, if the given string is one of the `acronymsi`
it is lowercasing it

given "URL" as parameter converted to "url" given "ProfileURL" as parameter
converted to "profile_url" given "Profile" as parameter converted to "profile"
given "ProfileName" as parameter converted to "profile_name"

#### func  ToLowerFirst

```go
func ToLowerFirst(ident string) string
```
ToLowerFirst lowers the first character of any given unicode char

#### func  ToUpperFirst

```go
func ToUpperFirst(ident string) string
```
ToUpperFirst converts the first character of any given unicode char to uppercase
