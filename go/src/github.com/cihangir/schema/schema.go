// Package schema provides json-schema reading, validation, support
package schema

// Schema represents a JSON Schema.
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
	Items           []*Schema   `json:"items,omitempty"`
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

	// Below variables are not in the json-schema specification, custom made for
	// this package

	// Holds the order of property, for more info https://github.com/json-schema/json-schema/issues/87
	PropertyOrder int `json:"propertyOrder,omitempty"`

	// Functions holds the functions of a schema,
	Functions map[string]*Schema `json:"functions,omitempty"`

	// if the struct, property or the function is exported or not
	Private bool `json:"private,omitempty"`

	// Generators holds the generator plugins for current schema
	Generators Generators `json:"generators,omitempty"`

	// rest endpoint paths
	Paths map[string]map[string]*Path `json:"paths,omitempty"`
}

type Path struct {
	Consumes    []string              `json:"consumes,omitempty"`
	Description string                `json:"description,omitempty"`
	OperationID string                `json:"operationId,omitempty"`
	Parameters  []*Parameter          `json:"parameters,omitempty"`
	Produces    []string              `json:"produces,omitempty"`
	Responses   map[string]*Schema    `json:"responses,omitempty"`
	Security    []map[string][]string `json:"security,omitempty"`
	Summary     string                `json:"summary,omitempty"`
	Tags        []string              `json:"tags,omitempty"`
}

type Parameter struct {
	Description string `json:"description,omitempty"`
	Format      string `json:"format,omitempty"`
	Maximum     int    `json:"maximum,omitempty"`
	Minimum     int    `json:"minimum,omitempty"`
	Type        string `json:"type,omitempty"`

	In       string  `json:"in,omitempty"`
	Name     string  `json:"name,omitempty"`
	Required bool    `json:"required,omitempty"`
	Schema   *Schema `json:"schema,omitempty"`
}

// Link represents a Link description.
type Link struct {
	Title        string  `json:"title,omitempty"`
	Description  string  `json:"description,omitempty"`
	HRef         *HRef   `json:"href,omitempty"`
	Rel          string  `json:"rel,omitempty"`
	Method       string  `json:"method,omitempty"`
	Schema       *Schema `json:"schema,omitempty"`
	TargetSchema *Schema `json:"targetSchema,omitempty"`
}

type Generator map[string]interface{}

func (g *Generator) Get(key string) interface{} {
	d, ok := (*g)[key]
	if !ok {
		return nil
	}

	return d
}

func (g *Generator) GetWithDefault(key string, def interface{}) interface{} {
	d, ok := (*g)[key]
	if !ok {
		return def
	}

	return d
}

func (g *Generator) SetNX(key string, val interface{}) {
	_, ok := (*g)[key]
	if !ok {
		g.Set(key, val)
	}
}

func (g *Generator) Set(key string, val interface{}) {
	if *g == nil {
		*g = make(map[string]interface{})
	}
	(*g)[key] = val
}

type Generators []map[string]Generator

func (g Generators) Has(s string) bool {
	_, has := g.Get(s)
	return has
}

func (g *Generators) Get(s string) (Generator, bool) {
	for _, m := range *g {
		if d, ok := m[s]; ok {
			return d, ok
		}
	}

	return nil, false
}
