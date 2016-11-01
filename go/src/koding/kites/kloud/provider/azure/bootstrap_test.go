package azure_test

import (
	"encoding/json"
	"testing"

	"koding/kites/kloud/provider/azure"
)

func TestBootstrapJSONTmpl(t *testing.T) {
	cases := []*azure.BootstrapConfig{
		{Rule: false},
		{Rule: true},
		{TeamSlug: "a"},
		{HostedServiceName: "b"},
		{StorageServiceName: "c"},
		{StorageType: "d"},
		{VirtualNetworkName: "e"},
		{},
		{TeamSlug: "a", HostedServiceName: "b", StorageServiceName: "c"},
	}

	for i, cas := range cases {
		tmpl, err := azure.NewBootstrapTmpl(cas)
		if err != nil {
			t.Fatalf("%d: NewBootstrapTmpl()=%s", i, err)
		}

		var v map[string]interface{}

		if err = json.Unmarshal(tmpl, &v); err != nil {
			t.Fatalf("%d: Unmarshal()=%s", i, err)
		}
	}
}
