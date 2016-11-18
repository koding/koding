package object_test

import (
	"koding/kites/kloud/utils/object"
	"reflect"
	"testing"
)

type Secret struct {
	Field string
	M     map[string]interface{}
}

func TestReplace(t *testing.T) {
	v := map[string]interface{}{
		"key": "secret",
		"m": map[string]interface{}{
			"key": "secret",
			"secret": &Secret{
				Field: "secret",
				M: map[string]interface{}{
					"key": "secret",
					"keys": []string{
						"secret",
						"secret",
						"secret",
					},
				},
			},
			"secrets": []*Secret{
				{Field: "secret"},
				{Field: "secret"},
				{M: map[string]interface{}{"key": "secret"}},
			},
			"ms": []interface{}{
				map[string]interface{}{"key": "secret"},
				&Secret{Field: "secret"},
				"secret",
			},
		},
	}

	want := map[string]interface{}{
		"key": "***",
		"m": map[string]interface{}{
			"key": "***",
			"secret": &Secret{
				Field: "***",
				M: map[string]interface{}{
					"key": "***",
					"keys": []string{
						"***",
						"***",
						"***",
					},
				},
			},
			"secrets": []*Secret{
				{Field: "***"},
				{Field: "***"},
				{M: map[string]interface{}{"key": "***"}},
			},
			"ms": []interface{}{
				map[string]interface{}{"key": "***"},
				&Secret{Field: "***"},
				"***",
			},
		},
	}

	fn := func(s string) string {
		if s == "secret" {
			return "***"
		}
		return ""
	}

	if err := object.ReplaceFunc(v, fn); err != nil {
		t.Fatalf("Walk()=%s", err)
	}

	if !reflect.DeepEqual(v, want) {
		t.Fatalf("got %+v, want %+v", v, want)
	}
}
