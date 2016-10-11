package provider_test

import (
	"reflect"
	"testing"

	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

type Foo struct {
	File []byte `kloud:",secret"`
	N    int    `kloud:",readOnly"`
	S    string
	M    map[string]interface{} `kloud:"someMap"`
	E    FooEnum                `json:"enums" kloud:"someEnums"`
}

type FooEnum string

var FooEnums = []stack.Enum{
	{Title: "A foo value", Value: "foo"},
	{Title: "A bar value", Value: "bar"},
	{Title: "A baz value", Value: "baz"},
}

func (FooEnum) Enums() []stack.Enum {
	return FooEnums
}

func TestDescribe(t *testing.T) {
	cases := map[string]struct {
		value interface{}
		desc  []stack.Value
	}{
		"AWS credential": {
			&aws.Cred{},
			[]stack.Value{{
				Name:   "access_key",
				Type:   "string",
				Label:  "Access Key ID",
				Secret: true,
			}, {
				Name:   "secret_key",
				Type:   "string",
				Label:  "Secret Access Key",
				Secret: true,
			}, {
				Name:   "region",
				Type:   "enum",
				Label:  "Region",
				Values: aws.Regions,
			}},
		},
		"arbitrary Foo": {
			&Foo{},
			[]stack.Value{{
				Name:   "File",
				Type:   "file",
				Label:  "File",
				Secret: true,
			}, {
				Name:     "N",
				Type:     "integer",
				Label:    "N",
				ReadOnly: true,
			}, {
				Name:  "S",
				Type:  "string",
				Label: "S",
			}, {
				Name:  "M",
				Type:  "object",
				Label: "someMap",
			}, {
				Name:   "enums",
				Type:   "enum",
				Label:  "someEnums",
				Values: FooEnums,
			}},
		},
	}

	for name, cas := range cases {
		desc, err := provider.Describe(cas.value)
		if err != nil {
			t.Errorf("%s: Describe()=%s", name, err)
			continue
		}

		if !reflect.DeepEqual(desc, cas.desc) {
			t.Errorf("%s: got %+v, want %+v", name, desc, cas.desc)
			continue
		}
	}
}
