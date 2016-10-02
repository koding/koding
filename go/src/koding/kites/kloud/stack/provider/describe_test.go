package provider_test

import (
	"reflect"
	"testing"

	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

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
				Type:   "string",
				Label:  "Region",
				Secret: false,
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
