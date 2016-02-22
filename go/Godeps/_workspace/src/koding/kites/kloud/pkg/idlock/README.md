[![GoDoc](http://img.shields.io/badge/godoc-Reference-brightgreen.svg?style=flat)](https://godoc.org/github.com/koding/idlock)

Idlock is a simple package to provide locks for individual unique ids. Useful
for using in webservers to use different locks for each individual context.
Locks are bound to a specific id. Locks are created lazily if they are non
existent.


## Install and Usage

Install the package with:

```bash
go get github.com/koding/idlock
```

## Example

```go

locks := idlock.New()

go func() {
	locks.Get("foo").Lock()
	defer locks.Get("foo").Undlock()

	// do stuff and lock only for "foo"
}()

go func() {
	locks.Get("bar").Lock()
	defer locks.Get("bar").Undlock()

	// do stuff and lock only for "bar"
}()

```
