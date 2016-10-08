package object_test

import (
	"koding/kites/kloud/utils/object"
	"reflect"
	"testing"
)

type Abc struct {
	S1 string
	S2 string
	S3 string
}

func TestMerge(t *testing.T) {
	cases := []struct {
		v1     interface{}
		v2     interface{}
		result interface{}
	}{{
		&Abc{S1: "v1.S1", S2: "v1.S2"},
		&Abc{S1: "v2.S1", S2: "", S3: "v2.S3"},
		&Abc{S1: "v2.S1", S2: "v1.S2", S3: "v2.S3"},
	}, {
		&Abc{},
		&Abc{S1: "v2.S1"},
		&Abc{S1: "v2.S1"},
	}, {
		&Abc{},
		&Abc{},
		&Abc{},
	}, {
		&Abc{S1: "v1.S1", S2: "v1.S2", S3: "v1.S3"},
		&Abc{},
		&Abc{S1: "v1.S1", S2: "v1.S2", S3: "v1.S3"},
	}}

	for i, cas := range cases {
		object.Merge(cas.v1, cas.v2)

		if !reflect.DeepEqual(cas.v1, cas.result) {
			t.Errorf("%d: got %#v, want %#v", i, cas.v1, cas.result)
		}
	}
}
