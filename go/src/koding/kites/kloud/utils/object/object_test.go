package object_test

import (
	"reflect"
	"testing"

	"koding/kites/kloud/utils/object"

	"gopkg.in/mgo.v2/bson"
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
	}, { // i=3
		map[string]interface{}{"foo": "bar", "baz": 42},
		object.Object{
			"prefix+foo": "bar",
			"prefix+baz": 42,
		},
	}, { // i=4
		bson.M{"foo": bson.M{"bar": "s"}, "baz": 42},
		object.Object{
			"prefix+foo+bar": "s",
			"prefix+baz":     42,
		},
	}, { // i=5
		struct{ Field bson.M }{Field: bson.M{"other": Bar{Bar: "s"}}},
		object.Object{
			"prefix+field+other+foos+foo": "",
			"prefix+field+other+barbar":   "s",
		},
	}}

	for i, cas := range cases {
		obj := b.Build(cas.v)
		if !reflect.DeepEqual(obj, cas.obj) {
			t.Errorf("%d: want %+v to be %+v", i, obj, cas.obj)
		}
	}
}
