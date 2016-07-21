# slug

`slug` is a package that sanitizes and normalizes strings for use in things like
URLs by removing / converting characters that are not in the set `[0-9A-Za-z]`:

```go
package main

import github.com/stvp/slug

func main() {
  slug.Clean("L'école 24") // "l_ecole_24"
  slug.Clean("\x00\x08clean") // "clean"
}
```

You can also customize the replacement string:

```go
package main

import github.com/stvp/slug

func main() {
  slug.Replacement = '-'
  slug.Clean("L'école 24") // "l-ecole-24"
}
```

[API docs](http://go.pkgdoc.org/github.com/stvp/slug)

