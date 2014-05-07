sanitize
========

Package sanitize provides functions for sanitizing text in golang strings.

FUNCTIONS
___

```go
func Accents(text string) string
```

Replace a set of accented characters with ascii equivalents.

```go
func HTML(s string) (output string)
```

Strip html tags, replace common entities, and escape < and > in the result. Later could consider taking options and allowing certain tags, attributes etc

```go
func Name(text string) string
```

Makes a string safe to use in a file name (e.g. for saving file atttachments)

```go
func Path(text string) string
```

Makes a string safe to use as an url path, cleaned of .. and unsuitable characters

