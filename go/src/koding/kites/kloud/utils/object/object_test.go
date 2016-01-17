package object_test

import (
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

func TestBuilderDecode(t *testing.T) {
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
	var meta = &awsprovider.AwsMeta{
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
		Tag:       "stackplan",
		Sep:       "_",
		Recursive: true,
	}

	decoded := &awsprovider.AwsMeta{}
	if err := b.Decode(RootModule, decoded); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(decoded, meta) {
		t.Errorf("want %+v to be %+v", decoded, meta)
	}
}
