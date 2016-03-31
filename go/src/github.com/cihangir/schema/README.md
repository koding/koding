# schema
Package schema provides json-schema reading, validation support
# schema
--
    import "github.com/cihangir/schema"

Package schema provides json-schema reading, validation, support

## Usage

```go
var Helpers = template.FuncMap{
	"AsComment":               stringext.AsComment,
	"JSONTag":                 stringext.JSONTag,
	"Params":                  Params,
	"Args":                    Args,
	"Values":                  Values,
	"goType":                  goType,
	"GenerateValidator":       generateValidator,
	"ToLowerFirst":            stringext.ToLowerFirst,
	"ToUpperFirst":            stringext.ToUpperFirst,
	"DepunctWithInitialUpper": stringext.DepunctWithInitialUpper,
	"DepunctWithInitialLower": stringext.DepunctWithInitialLower,
}
```
Helpers holds helpers for templates

#### func  Args

```go
func Args(h *HRef) string
```
Args creates arguments string

#### func  Params

```go
func Params(l *Link) string
```
Params creates the parameter string for the given link

#### func  Parse

```go
func Parse(t *template.Template) (*template.Template, error)
```
Parse parses declared templates.

#### func  Required

```go
func Required(n string, def *Schema) bool
```
Required checks if the given n is a required property

#### func  Values

```go
func Values(n string, s *Schema, l *Link) string
```
Values creates the value string

#### type HRef

```go
type HRef struct {
	Order   []string
	Schemas map[string]*Schema
}
```

HRef represents a Link href.

#### func  NewHRef

```go
func NewHRef(href string) *HRef
```
NewHRef creates a new HRef struct based on a href value.

#### func (*HRef) MarshalJSON

```go
func (h *HRef) MarshalJSON() ([]byte, error)
```
MarshalJSON returns *h as the JSON encoding of h.

#### func (*HRef) Resolve

```go
func (h *HRef) Resolve(r *Schema)
```
Resolve resolves a href inside a Schema.

#### func (*HRef) String

```go
func (h *HRef) String() string
```

#### func (*HRef) URL

```go
func (h *HRef) URL() (*url.URL, error)
```
URL returns a usable URL for the href.

#### func (*HRef) UnmarshalJSON

```go
func (h *HRef) UnmarshalJSON(data []byte) error
```
UnmarshalJSON sets *h to a copy of data.

#### type Link

```go
type Link struct {
	Title       string  `json:"title,omitempty"`
	Description string  `json:"description,omitempty"`
	HRef        *HRef   `json:"href,omitempty"`
	Rel         string  `json:"rel,omitempty"`
	Method      string  `json:"method,omitempty"`
	Schema      *Schema `json:"schema,omitempty"`
}
```

Link represents a Link description.

#### func (*Link) GoType

```go
func (l *Link) GoType() string
```
GoType returns Go type for the given schema as string.

#### func (*Link) Parameters

```go
func (l *Link) Parameters() ([]string, map[string]string)
```
Parameters returns function parameters names and types.

#### func (*Link) Resolve

```go
func (l *Link) Resolve(r *Schema)
```
Resolve resolve link schema and href.

#### type Reference

```go
type Reference string
```

Reference represents a JSON Reference.

#### func (Reference) Resolve

```go
func (rf Reference) Resolve(r *Schema) *Schema
```
Resolve resolves reference inside a Schema.

#### type Schema

```go
type Schema struct {
	ID          string `json:"id,omitempty"`
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
	Version     string `json:"version,omitempty"`

	Default  interface{} `json:"default,omitempty"`
	ReadOnly bool        `json:"readOnly,omitempty"`
	Example  interface{} `json:"example,omitempty"`
	Format   string      `json:"format,omitempty"`

	Type interface{} `json:"type,omitempty"`

	Ref    *Reference `json:"$ref,omitempty"`
	Schema *Reference `json:"$schema,omitempty"`

	Definitions map[string]*Schema `json:"definitions,omitempty"`

	// Numbers
	MultipleOf       float64 `json:"multipleOf,omitempty"`
	Maximum          float64 `json:"maximum,omitempty"`
	ExclusiveMaximum bool    `json:"exclusiveMaximum,omitempty"`
	Minimum          float64 `json:"minimum,omitempty"`
	ExclusiveMinimum bool    `json:"exclusiveMinimum,omitempty"`

	// Strings
	MinLength int    `json:"minLength,omitempty"`
	MaxLength int    `json:"maxLength,omitempty"`
	Pattern   string `json:"pattern,omitempty"`

	// Objects
	MinProperties        int                    `json:"minProperties,omitempty"`
	MaxProperties        int                    `json:"maxProperties,omitempty"`
	Required             []string               `json:"required,omitempty"`
	Properties           map[string]*Schema     `json:"properties,omitempty"`
	Dependencies         map[string]interface{} `json:"dependencies,omitempty"`
	AdditionalProperties interface{}            `json:"additionalProperties,omitempty"`
	PatternProperties    map[string]*Schema     `json:"patternProperties,omitempty"`

	// Arrays
	Items           *Schema     `json:"items,omitempty"`
	MinItems        int         `json:"minItems,omitempty"`
	MaxItems        int         `json:"maxItems,omitempty"`
	UniqueItems     bool        `json:"uniqueItems,omitempty"`
	AdditionalItems interface{} `json:"additionalItems,omitempty"`

	// All
	Enum []string `json:"enum,omitempty"`

	// Schemas
	OneOf []Schema `json:"oneOf,omitempty"`
	AnyOf []Schema `json:"anyOf,omitempty"`
	AllOf []Schema `json:"allOf,omitempty"`
	Not   *Schema  `json:"not,omitempty"`

	// Links
	Links []Link `json:"links,omitempty"`
}
```

Schema represents a JSON Schema.

#### func (*Schema) GoType

```go
func (s *Schema) GoType() string
```
GoType returns the Go type for the given schema as string.

#### func (*Schema) IsCustomType

```go
func (s *Schema) IsCustomType() bool
```
IsCustomType returns true if the schema declares a custom type.

#### func (*Schema) Resolve

```go
func (s *Schema) Resolve(r *Schema) *Schema
```
Resolve resolves reference inside the schema.

#### func (*Schema) Types

```go
func (s *Schema) Types() (types []string)
```
Types returns the array of types described by this schema.

#### func (*Schema) URL

```go
func (s *Schema) URL() string
```
URL returns schema base URL.

#### func (*Schema) Values

```go
func (s *Schema) Values(name string, l *Link) []string
```
Values returns function return values types.
