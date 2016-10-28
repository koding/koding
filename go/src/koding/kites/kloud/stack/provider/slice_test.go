package provider_test

import (
	"encoding/json"
	"koding/kites/kloud/stack/provider"
	"reflect"
	"testing"
)

func TestSlice(t *testing.T) {
	cases := map[string]struct {
		raw  string
		want []interface{}
	}{
		"string slice": {
			`["a","b","c","d","e","f"]`,
			[]interface{}{"a", "b", "c", "d", "e", "f"},
		},
		"float slice": {
			`[1,2,4,8]`,
			[]interface{}{1.0, 2.0, 4.0, 8.0},
		},
		"nil slice": {
			`[null,null,null]`,
			[]interface{}{nil, nil, nil},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			var s provider.Slice

			if err := json.Unmarshal([]byte(cas.raw), &s); err != nil {
				t.Fatalf("Unmarshal()=%s", err)
			}

			got := provider.FromSlice(s)

			if !reflect.DeepEqual(got, cas.want) {
				t.Fatalf("got %+v, want %+v", got, cas.want)
			}

			p, err := json.Marshal(s)
			if err != nil {
				t.Fatalf("Marshal()=%s", err)
			}

			if cas.raw != string(p) {
				t.Fatalf("got %s, want %s", p, cas.raw)
			}
		})
	}
}

func TestToPrimitiveSlice(t *testing.T) {
	want := provider.PrimitiveSlice{
		"0": {Value: 0},
		"1": {Value: 0},
		"2": {Value: 0},
	}
	got := provider.ToPrimitiveSlice([]interface{}{0, 0, 0})

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}

func TestPrimitiveSlice(t *testing.T) {
	cases := map[string]struct {
		raw  string
		want []interface{}
	}{
		"string slice": {
			`["a","b","c","d","e","f"]`,
			[]interface{}{"a", "b", "c", "d", "e", "f"},
		},
		"float slice": {
			`[1,2,4,8]`,
			[]interface{}{1.0, 2.0, 4.0, 8.0},
		},
		"nil slice": {
			`[null,null,null]`,
			[]interface{}{nil, nil, nil},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			var s provider.PrimitiveSlice

			if err := json.Unmarshal([]byte(cas.raw), &s); err != nil {
				t.Fatalf("Unmarshal()=%s", err)
			}

			got := provider.FromPrimitiveSlice(s)

			if !reflect.DeepEqual(got, cas.want) {
				t.Fatalf("got %+v, want %+v", got, cas.want)
			}

			p, err := json.Marshal(s)
			if err != nil {
				t.Fatalf("Marshal()=%s", err)
			}

			if cas.raw != string(p) {
				t.Fatalf("got %s, want %s", p, cas.raw)
			}
		})
	}
}
