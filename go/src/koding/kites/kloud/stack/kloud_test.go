package stack_test

import (
	"koding/kites/kloud/stack"
	"reflect"
	"testing"
)

func TestReadProviders(t *testing.T) {
	cases := map[string]struct {
		tmpl      string
		providers []string
		err       bool
	}{
		"single provider": {
			`{"provider": {"google": {}}}`,
			[]string{"google"},
			false,
		},
		"multiple providers": {
			`{"provider": {"google": {}, "aws": {}}}`,
			[]string{"aws", "google"},
			false,
		},
		"no providers": {
			`{"provider": {}}`,
			[]string{},
			false,
		},
		"invalid template": {
			"[]",
			nil,
			true,
		},
	}

	for name, cas := range cases {
		// capture range variable here
		cas := cas
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			providers, err := stack.ReadProviders([]byte(cas.tmpl))

			if cas.err {
				if err == nil {
					t.Fatal("expected err to be non-nil")
				}

				return
			}

			if !reflect.DeepEqual(providers, cas.providers) {
				t.Fatalf("got %#v, want %#v", providers, cas.providers)
			}
		})
	}
}
