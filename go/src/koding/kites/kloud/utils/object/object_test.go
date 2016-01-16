package object_test

import (
	"koding/kites/kloud/utils/object"
	"reflect"
	"testing"
)

type Foo struct {
	Dupa string `object:"foo"`
}

type Bar struct {
	Foos []*Foo
	Bar  string `object:"barbar"`
}

type Baz struct {
	Foo *Foo `object:"foofoo"`
	Bar Bar
	Baz int
}

func TestBuilder(t *testing.T) {
	b := &object.Builder{
		Tag:       "object",
		Sep:       "+",
		Prefix:    "prefix",
		Recursive: true,
	}

	cases := []struct {
		v   interface{}
		obj object.Object
	}{{ // i=0
		Foo{Dupa: "s"},
		object.Object{
			"prefix+foo": "s",
		},
	}, { // i=1
		Bar{Bar: "s"},
		object.Object{
			"prefix+foos+foo": "", // see package-level TODO in object.go
			"prefix+barbar":   "s",
		},
	}, { // i=2
		Baz{Foo: &Foo{Dupa: "s"}, Bar: Bar{Bar: "z"}, Baz: 42},
		object.Object{
			"prefix+foofoo+foo":   "s",
			"prefix+bar+foos+foo": "",
			"prefix+bar+barbar":   "z",
			"prefix+baz":          42,
		},
	}}

	for i, cas := range cases {
		obj := b.Build(cas.v)
		if !reflect.DeepEqual(obj, cas.obj) {
			t.Errorf("%d: want %+v to be %+v", i, obj, cas.obj)
		}
	}
}
