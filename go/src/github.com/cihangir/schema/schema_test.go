package schema

import (
	"encoding/json"
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
