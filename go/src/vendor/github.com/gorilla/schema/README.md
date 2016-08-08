schema
======
[![GoDoc](https://godoc.org/github.com/gorilla/schema?status.svg)](https://godoc.org/github.com/gorilla/schema) [![Build Status](https://travis-ci.org/gorilla/schema.png?branch=master)](https://travis-ci.org/gorilla/schema)

Package gorilla/schema fills a struct with form values.

## Example

Here's a quick example: we parse POST form values and then decode them into a struct:

```go
// Set a Decoder instance as a package global, because it caches 
// meta-data about structs, and an instance can be shared safely.
var decoder = schema.NewDecoder()

type Person struct {
    Name  string
    Phone string
}

func MyHandler(w http.ResponseWriter, r *http.Request) {
    err := r.ParseForm()

    if err != nil {
        // Handle error
    }

    person := &Person{}
    decoder := schema.NewDecoder()

    // r.PostForm is a map of our POST form values
    err := decoder.Decode(person, r.PostForm)

    if err != nil {
        // Handle error
    }

    // Do something with person.Name or person.Phone
}
```

To define custom names for fields, use a struct tag "schema". To not populate certain fields, use a dash for the name and it will be ignored:

```go
type Person struct {
    Name  string `schema:"name"`  // custom name
    Phone string `schema:"phone"` // custom name
    Admin bool   `schema:"-"`     // this field is never set
}
```

The supported field types in the destination struct are:

* bool
* float variants (float32, float64)
* int variants (int, int8, int16, int32, int64)
* string
* uint variants (uint, uint8, uint16, uint32, uint64)
* struct
* a pointer to one of the above types
* a slice or a pointer to a slice of one of the above types

Unsupported types are simply ignored, however custom types can be registered to be converted.

More examples are available on the Gorilla website: http://www.gorillatoolkit.org/pkg/schema

## License 

BSD licensed. See the LICENSE file for details.
