package stack_test

import (
	"encoding/json"
	"reflect"
	"testing"

	"koding/kites/kloud/utils/object"
	"koding/klientctl/endpoint/stack/stackfixture"

	"github.com/hashicorp/hcl"
)

func TestFixHCL(t *testing.T) {
	var vHCL interface{}

	if err := hcl.Unmarshal(stackfixture.StackHCL, &vHCL); err != nil {
		t.Fatalf("hcl.Unmarshal()=%s", err)
	}

	if testing.Verbose() {
		t.Logf("original (vHCL):\n%s", mustJSON(vHCL))
	}

	if reflect.DeepEqual(vHCL, stackfixture.Stack) {
		t.Fatal("expected HCL-encoded stack to not unmarshal cleanly")
	}

	object.FixHCL(vHCL)

	if !reflect.DeepEqual(vHCL, stackfixture.Stack) {
		t.Fatalf("got %+v, want %+v", vHCL, stackfixture.Stack)
	}

	var vJSON interface{}

	if err := json.Unmarshal(stackfixture.StackJSON, &vJSON); err != nil {
		t.Fatalf("json.Unmarshal()=%s", err)
	}

	if testing.Verbose() {
		t.Logf("fixed (vJSON):\n%s", mustJSON(vJSON))
	}

	if !reflect.DeepEqual(vJSON, vHCL) {
		t.Fatalf("got %+v, want %+v", vJSON, vHCL)
	}
}

func TestFixYAML(t *testing.T) {
	cases := map[string]struct {
		yaml interface{}
		want interface{}
	}{
		"fix map": {
			map[interface{}]interface{}{
				"abc": 1,
			},
			map[string]interface{}{
				"abc": 1,
			},
		},
		"fix slice of maps": {
			[]interface{}{
				"abc",
				map[interface{}]interface{}{
					"abc": 1,
				},
				1,
			},
			[]interface{}{
				"abc",
				map[string]interface{}{
					"abc": 1,
				},
				1,
			},
		},
		"fix nested maps": {
			map[interface{}]interface{}{
				"abc": map[interface{}]interface{}{
					"abc": map[interface{}]interface{}{
						"abc": 1,
					},
				},
			},
			map[string]interface{}{
				"abc": map[string]interface{}{
					"abc": map[string]interface{}{
						"abc": 1,
					},
				},
			},
		},
	}

	for name, cas := range cases {
		// capture range variable here
		cas := cas
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			got := object.FixYAML(cas.yaml)

			if !reflect.DeepEqual(got, cas.want) {
				t.Fatalf("got %#v, want %#v", got, cas.want)
			}
		})
	}
}

func mustJSON(v interface{}) []byte {
	p, err := json.MarshalIndent(v, "", "\t")
	if err != nil {
		panic(err)
	}

	return p
}
