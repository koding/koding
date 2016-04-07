package schema

import (
	"encoding/json"
	"strings"
	"testing"
)

const testJSON1 = `
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "title": "Message",
    "description": "Message represents a simple post",
    "type": "object",
    "properties": {
        "Id": {
            "description": "The unique identifier for a message",
            "type": "number",
            "format": "int64",
            "propertyOrder": 10
        },
        "Token": {
            "description": "The token for a message security",
            "type": "string",
            "propertyOrder": 20
        },
        "Body": {
            "description": "The body for a message",
            "type": "string",
            "pattern": "^(/[^/]+)+$",
            "minLength": 2,
            "maxLength": 3,
            "propertyOrder": 15
        },
        "Age": {
            "type": "integer",
            "minimum": 0,
            "maximum": 100,
            "exclusiveMaximum": true
        },
        "Enabled": {
            "type": "boolean"
        },
        "StatusConstant": {
            "type": "string",
            "enum": [
                "active",
                "deleted"
            ]
        },
        "CreatedAt": {
            "type": "string",
            "format": "date-time"
        }
    },
    "required": [
        "id",
        "body"
    ]
}
`

var order = []string{"Id", "Body", "Token", "Age", "CreatedAt", "Enabled", "StatusConstant"}

func TestSortedKeys(t *testing.T) {
	s := &Schema{}
	err := json.Unmarshal([]byte(testJSON1), s)
	if err != nil {
		t.Fatalf(err.Error())
	}
	s.Resolve(s)

	keys := SortedKeys(s.Properties)
	for i, k := range keys {
		if k != order[i] {
			t.Fatalf("%d th item should be: %s, got: %s", i, order[i], k)
		}
	}
}

func TestSortedSchema(t *testing.T) {
	s := &Schema{}
	err := json.Unmarshal([]byte(testJSON1), s)
	if err != nil {
		t.Fatalf(err.Error())
	}
	s.Resolve(s)

	ss := SortedSchema(s.Properties)
	for i, k := range ss {
		if k.Title != order[i] {
			t.Fatalf("%d th item should be: %s, got: %s", i, order[i], k.Title)
		}
	}
}

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
