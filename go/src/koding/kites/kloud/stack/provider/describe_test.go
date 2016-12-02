package provider_test

import (
	"reflect"
	"testing"
	"time"

	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

type Foo struct {
	File          []byte `kloud:",secret"`
	N             int    `kloud:",readOnly"`
	S             string
	M             map[string]interface{} `kloud:"someMap"`
	E             FooEnum                `json:"enums" kloud:"someEnums"`
	ThisIsTimeout time.Duration
	AlsoTimeout   time.Duration `json:"also_timeout"`
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
			}, {
				Name:  "ThisIsTimeout",
				Type:  "duration",
				Label: "This Is Timeout",
			}, {
				Name:  "also_timeout",
				Type:  "duration",
				Label: "Also Timeout",
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

func TestTitle(t *testing.T) {
	cases := map[string]string{
		"this_is_some_title": "This Is Some Title",
		"ThisIsSomeTitle":    "This Is Some Title",
		"ANDThisIsALSO":      "AND This Is ALSO",
		"me_too":             "Me Too",
		"same":               "Same",
		"s":                  "S",
		"This Is a Title":    "This Is A Title",
	}

	for s, want := range cases {
		got := provider.Title(s)

		if got != want {
			t.Errorf("%s: got %q, want %q", s, got, want)
		}
	}
}
