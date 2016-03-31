package schema

import (
	"reflect"
	"strings"
	"testing"
)

var typeTests = []struct {
	Schema *Schema
	Type   string
}{
	{
		Schema: &Schema{
			Type: "boolean",
		},
		Type: "bool",
	},
	{
		Schema: &Schema{
			Type: "number",
		},
		Type: "float64",
	},
	{
		Schema: &Schema{
			Type: "integer",
		},
		Type: "int",
	},
	{
		Schema: &Schema{
			Type: "any",
		},
		Type: "interface{}",
	},
	{
		Schema: &Schema{
			Type: "string",
		},
		Type: "string",
	},
	{
		Schema: &Schema{
			Type:   "string",
			Format: "date-time",
		},
		Type: "time.Time",
	},
	{
		Schema: &Schema{
			Type: []interface{}{"null", "string"},
		},
		Type: "*string",
	},
	{
		Schema: &Schema{
			Type: "array",
			Items: []*Schema{&Schema{
				Type: "string",
			}},
		},
		Type: "[]string",
	},
	{
		Schema: &Schema{
			Type: "array",
		},
		Type: "[]interface{}",
	},
	{
		Schema: &Schema{
			Type:                 "object",
			AdditionalProperties: false,
			PatternProperties: map[string]*Schema{
				"^\\w+$": {
					Type: "string",
				},
			},
		},
		Type: "map[string]string",
	},
	{
		Schema: &Schema{
			Type:                 "object",
			AdditionalProperties: false,
			PatternProperties: map[string]*Schema{
				"^\\w+$": {
					Type: []interface{}{"string", "null"},
				},
			},
		},
		Type: "map[string]*string",
	},
	{
		Schema: &Schema{
			Type: "object",
			Properties: map[string]*Schema{
				"counter": {
					Type: "integer",
				},
			},
			Required: []string{"counter"},
		},
		Type: "Counter int",
	},
	{
		Schema: &Schema{
			Type:   []interface{}{"null", "string"},
			Format: "date-time",
		},
		Type: "*time.Time",
	},
}

func TestSchemaType(t *testing.T) {
	for i, tt := range typeTests {
		kind := tt.Schema.GoType()
		if !strings.Contains(kind, tt.Type) {
			t.Errorf("%d: wants %v, got %v", i, tt.Type, kind)
		}
	}
}

var linkTests = []struct {
	Link *Link
	Type string
}{
	{
		Link: &Link{
			Schema: &Schema{
				Properties: map[string]*Schema{
					"string": {
						Type: "string",
					},
				},
				Type:     "object",
				Required: []string{"string"},
			},
		},
		Type: "String string",
	},
	{
		Link: &Link{
			Schema: &Schema{
				Properties: map[string]*Schema{
					"int": {
						Type: "integer",
					},
				},
				Type: "object",
			},
		},
		Type: "Int *int",
	},
}

func TestLinkType(t *testing.T) {
	for i, lt := range linkTests {
		kind := lt.Link.GoType()
		if !strings.Contains(kind, lt.Type) {
			t.Errorf("%d: wants %v, got %v", i, lt.Type, kind)
		}
	}
}

var paramsTests = []struct {
	Schema     *Schema
	Link       *Link
	Order      []string
	Parameters map[string]string
}{
	{
		Schema: &Schema{},
		Link: &Link{
			HRef: NewHRef("/destroy/"),
			Rel:  "destroy",
		},
		Parameters: map[string]string{},
	},
	{
		Schema: &Schema{},
		Link: &Link{
			HRef: NewHRef("/instances/"),
			Rel:  "instances",
		},
		Order:      []string{"lr"},
		Parameters: map[string]string{"lr": "*ListRange"},
	},
	{
		Schema: &Schema{},
		Link: &Link{
			Rel:  "update",
			HRef: NewHRef("/update/"),
			Schema: &Schema{
				Type: "string",
			},
		},
		Order:      []string{"o"},
		Parameters: map[string]string{"o": "string"},
	},
	{
		Schema: &Schema{
			Definitions: map[string]*Schema{
				"struct": {
					Definitions: map[string]*Schema{
						"uuid": {
							Type: "string",
						},
					},
				},
			},
		},
		Link: &Link{
			HRef: NewHRef("/results/{(%23%2Fdefinitions%2Fstruct%2Fdefinitions%2Fuuid)}"),
		},
		Order:      []string{"structUUID"},
		Parameters: map[string]string{"structUUID": "string"},
	},
}

func TestParameters(t *testing.T) {
	for i, pt := range paramsTests {
		pt.Link.Resolve(pt.Schema)
		order, params := pt.Link.Parameters()
		if !reflect.DeepEqual(order, pt.Order) {
			t.Errorf("%d: wants %v, got %v", i, pt.Order, order)
		}
		if !reflect.DeepEqual(params, pt.Parameters) {
			t.Errorf("%d: wants %v, got %v", i, pt.Parameters, params)
		}

	}
}

var valuesTests = []struct {
	Schema *Schema
	Name   string
	Link   *Link
	Values []string
}{
	{
		Schema: &Schema{},
		Name:   "Result",
		Link: &Link{
			Rel: "destroy",
		},
		Values: []string{"error"},
	},
	{
		Schema: &Schema{},
		Name:   "Result",
		Link: &Link{
			Rel: "instances",
		},
		Values: []string{"[]*Result", "error"},
	},
	{
		Schema: &Schema{
			Type: "object",
			Properties: map[string]*Schema{
				"value": {
					Type: "integer",
				},
			},
			Required: []string{"value"},
		},
		Name: "Result",
		Link: &Link{
			Rel: "self",
		},
		Values: []string{"*Result", "error"},
	},
	{
		Schema: &Schema{
			Type:                 "object",
			AdditionalProperties: false,
			PatternProperties: map[string]*Schema{
				"^\\w+$": {
					Type: "string",
				},
			},
		},
		Name: "ConfigVar",
		Link: &Link{
			Rel: "self",
		},
		Values: []string{"map[string]string", "error"},
	},
}

func TestValues(t *testing.T) {
	for i, vt := range valuesTests {
		values := vt.Schema.Values(vt.Name, vt.Link)
		if !reflect.DeepEqual(values, vt.Values) {
			t.Errorf("%d: wants %v, got %v", i, vt.Values, values)
		}
	}
}
