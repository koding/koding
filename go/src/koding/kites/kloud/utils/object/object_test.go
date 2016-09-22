package object_test

import (
	"encoding/json"
	"reflect"
	"testing"

	"koding/kites/kloud/provider/aws"
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
		v       interface{}
		ignored []string
		obj     object.Object
	}{{ // i=0
		Foo{Dupa: "s"}, nil,
		object.Object{
			"prefix+foo": "s",
		},
	}, { // i=1
		Bar{Bar: "s"}, nil,
		object.Object{
			"prefix+foos+foo": "", // see package-level TODO in object.go
			"prefix+barbar":   "s",
		},
	}, { // i=2
		Baz{Foo: &Foo{Dupa: "s"}, Bar: Bar{Bar: "z"}, Baz: 42}, nil,
		object.Object{
			"prefix+foofoo+foo":   "s",
			"prefix+bar+foos+foo": "",
			"prefix+bar+barbar":   "z",
			"prefix+baz":          42,
		},
	}, { // i=3
		map[string]interface{}{"foo": "bar", "baz": 42}, nil,
		object.Object{
			"prefix+foo": "bar",
			"prefix+baz": 42,
		},
	}, { // i=4
		bson.M{"foo": bson.M{"bar": "s"}, "baz": 42}, nil,
		object.Object{
			"prefix+foo+bar": "s",
			"prefix+baz":     42,
		},
	}, { // i=5
		struct{ Field bson.M }{Field: bson.M{"other": Bar{Bar: "s"}}}, nil,
		object.Object{
			"prefix+field+other+foos+foo": "",
			"prefix+field+other+barbar":   "s",
		},
	}, { // i=6
		&map[string]*map[string]string{"foo": {"bar": "s"}}, nil,
		object.Object{
			"prefix+foo+bar": "s",
		},
	}, { // i=7
		struct{ Field *map[string]interface{} }{Field: &map[string]interface{}{"value": "s"}}, nil,
		object.Object{
			"prefix+field+value": "s",
		},
	}, { // i=8
		Baz{Foo: &Foo{Dupa: "s"}, Bar: Bar{Bar: "z"}, Baz: 42}, []string{"prefix+bar"},
		object.Object{
			"prefix+foofoo+foo": "s",
			"prefix+baz":        42,
		},
	}, { // i=9
		bson.M{"foo": bson.M{"bar": "s"}, "baz": 42}, []string{"prefix+baz"},
		object.Object{
			"prefix+foo+bar": "s",
		},
	}}

	for i, cas := range cases {
		obj := b.Build(cas.v, cas.ignored...)
		if !reflect.DeepEqual(obj, cas.obj) {
			t.Errorf("%d: want %+v to be %+v", i, obj, cas.obj)
		}
	}
}

func TestBuilderDecode(t *testing.T) {
	b := &object.Builder{
		Tag: "object",
	}

	cases := []struct {
		in   interface{}
		out  interface{}
		want interface{}
	}{{ // i=0
		json.RawMessage([]byte(`{"dupa": "bar"}`)),
		&Foo{},
		&Foo{Dupa: "bar"},
	}, { // i=1
		bson.M{"dupa": "bar"},
		&Foo{},
		&Foo{Dupa: "bar"},
	}, { // i=2
		[]byte(`{"bar": "foo"}`),
		&Bar{},
		&Bar{Bar: "foo"},
	}, { // i=3
		&bson.Raw{
			Kind: 3,
			Data: []byte{
				0x13, 0x0, 0x0, 0x0, 0x2, 0x64, 0x75, 0x70, 0x61, 0x0,
				0x4, 0x0, 0x0, 0x0, 0x66, 0x6f, 0x6f, 0x0, 0x0,
			},
		},
		&Foo{},
		&Foo{Dupa: "foo"},
	}, { // i=4
		&Baz{Foo: &Foo{Dupa: "bar"}},
		&Baz{},
		&Baz{Foo: &Foo{Dupa: "bar"}},
	}}

	for i, cas := range cases {
		if err := b.Decode(cas.in, cas.out); err != nil {
			t.Errorf("%d: Decode()=%s", i, err)
			continue
		}

		if !reflect.DeepEqual(cas.out, cas.want) {
			t.Errorf("%d: got %# v, want %# v", i, cas.out, cas.want)
		}
	}
}

func TestBuilderDecodeAwsMeta(t *testing.T) {
	var RootModule = map[string]string{
		"cidr_block": "10.0.0.0/16",
		"igw":        "igw-aa43bdce",
		"rtb":        "rtb-3e19315a",
		"sg":         "sg-bf1898c6",
		"subnet":     "subnet-5c0bf704",
		"acl":        "acl-0948336d",
		"key_pair":   "koding-deployment-rafal-1453026316070088464",
		"vpc":        "vpc-f0e09594",
		"ami":        "ami-cf35f3a4",
	}
	var meta = &awsprovider.Cred{
		CidrBlock: "10.0.0.0/16",
		IGW:       "igw-aa43bdce",
		RTB:       "rtb-3e19315a",
		SG:        "sg-bf1898c6",
		Subnet:    "subnet-5c0bf704",
		ACL:       "acl-0948336d",
		KeyPair:   "koding-deployment-rafal-1453026316070088464",
		VPC:       "vpc-f0e09594",
		AMI:       "ami-cf35f3a4",
	}
	b := &object.Builder{
		Tag:       "hcl",
		Sep:       "_",
		Recursive: true,
	}

	decoded := &awsprovider.Cred{}
	if err := b.Decode(RootModule, decoded); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(decoded, meta) {
		t.Errorf("want %+v to be %+v", decoded, meta)
	}
}
