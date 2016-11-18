package azure_test

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"reflect"
	"strings"
	"testing"

	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/provider/azure"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/kite/testkeys"
	"github.com/koding/logging"
)

var publishSettings = `<?xml version="1.0" encoding="utf-8"?>
<PublishData>
  <PublishProfile
    SchemaVersion="2.0"
    PublishMethod="AzureServiceManagementAPI">
    <Subscription
      ServiceManagementUrl="https://management.core.windows.net"
      Id="aa3ed1eb-ff8c-4312-b2f9-11cf611563b4"
      Name="Pay-As-You-Go"
      ManagementCertificate="..." />
    <Subscription
      ServiceManagementUrl="https://management.core.windows.net"
      Id="8a523531-2d66-469d-9228-718ad2a58eff"
      Name="Free Trial"
      ManagementCertificate="..." />
  </PublishProfile>
</PublishData>
`

func TestAzureMeta_PublishSettings(t *testing.T) {
	cases := map[string]struct {
		meta  *azure.Cred
		valid bool
	}{
		"valid Free Trial": {
			meta: &azure.Cred{
				PublishSettings: publishSettings,
				SubscriptionID:  "8a523531-2d66-469d-9228-718ad2a58eff",
			},
			valid: true,
		},
		"valid Pay-As-You-Go": {
			meta: &azure.Cred{
				PublishSettings: publishSettings,
				SubscriptionID:  "aa3ed1eb-ff8c-4312-b2f9-11cf611563b4",
			},
			valid: true,
		},
		"missing subscription ID": {
			meta: &azure.Cred{
				PublishSettings: publishSettings,
			},
			valid: false,
		},
		"invalid subscription ID": {
			meta: &azure.Cred{
				PublishSettings: publishSettings,
				SubscriptionID:  "invalid",
			},
			valid: false,
		},
	}

	for desc, cas := range cases {
		err := cas.meta.Valid()

		if cas.valid && err != nil {
			t.Fatalf("%s: got %# v, want nil", desc, err)
		}

		if !cas.valid && err == nil {
			t.Fatalf("%s: got nil, want non-nil error", desc)
		}
	}
}

func TestAzure_ApplyTemplate(t *testing.T) {
	log := logging.NewCustom("test", true)

	cred := &stack.Credential{
		Credential: &azure.Cred{
			PublishSettings:  "publish_settings",
			SSHKeyThumbprint: "12:23:45:56:67:89:90",
		},
		Bootstrap: &azure.Bootstrap{
			AddressSpace:     "10.10.10.10/16",
			StorageServiceID: "storage-serice",
			HostedServiceID:  "hosted-service",
			SecurityGroupID:  "security-group",
			VirtualNetworkID: "virtual-network",
			SubnetName:       "subnet",
		},
	}

	cases := map[string]struct {
		stackFile string
		wantFile  string
	}{
		"basic stack": {
			"testdata/basic-stack.json",
			"testdata/basic-stack.json.golden",
		},
		"custom endpoint": {
			"testdata/custom-endpoint.json",
			"testdata/custom-endpoint.json.golden",
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			content, err := ioutil.ReadFile(cas.stackFile)
			if err != nil {
				t.Fatalf("ReadFile(%s)=%s", cas.stackFile, err)
			}

			want, err := ioutil.ReadFile(cas.wantFile)
			if err != nil {
				t.Fatalf("ReadFile(%s)=%s", cas.wantFile, err)
			}

			template, err := provider.ParseTemplate(string(content), log)
			if err != nil {
				t.Fatalf("ParseTemplate()=%s", err)
			}

			s := &azure.Stack{
				BaseStack: &provider.BaseStack{
					Session: &session.Session{
						Userdata: &userdata.Userdata{
							KlientURL: "http://127.0.0.1/klient.gz",
							Keycreator: &keycreator.Key{
								KontrolURL:        "http://127.0.0.1/kontrol/kite",
								KontrolPublicKey:  testkeys.Public,
								KontrolPrivateKey: testkeys.Private,
							},
						},
					},
					Builder: &provider.Builder{
						Template: template,
					},
					Req: &kite.Request{
						Username: "user",
					},
					KlientIDs: make(stack.KiteMap),
				},
			}

			stack, err := s.ApplyTemplate(cred)
			if err != nil {
				t.Fatalf("ApplyTemplate()=%s", err)
			}

			if err := equal(stack.Content, string(want)); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func equal(got, want string) error {
	var v1, v2 interface{}

	if err := json.Unmarshal([]byte(got), &v1); err != nil {
		return err
	}

	if err := json.Unmarshal([]byte(want), &v2); err != nil {
		return err
	}

	stripNondeterministicResources(v1)
	stripNondeterministicResources(v2)

	if !reflect.DeepEqual(v1, v2) {
		p1, err := json.MarshalIndent(v1, "", "\t")
		if err != nil {
			panic(err)
		}

		p2, err := json.MarshalIndent(v2, "", "\t")
		if err != nil {
			panic(err)
		}

		return fmt.Errorf("got:\n%s\nwant:\n%s\n", p1, p2)
	}

	return nil
}

// stripNondeterministicResources sets the following fields to "...",
// as they change between test runs:
//
//   - resource.azure_instance.*.custom_data
//   - variable.kitekeys_*.default.*
//
func stripNondeterministicResources(v interface{}) {
	m, ok := v.(map[string]interface{})
	if !ok {
		return
	}

	resource, ok := m["resource"].(map[string]interface{})
	if !ok {
		return
	}

	instance, ok := resource["azure_instance"].(map[string]interface{})
	if !ok {
		return
	}

	for _, v := range instance {
		vm, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		vm["custom_data"] = "..."
		vm["name"] = "..."
	}

	variable, ok := m["variable"].(map[string]interface{})
	if !ok {
		return
	}

	for name, v := range variable {
		if !strings.HasPrefix(name, "kitekeys_") && !strings.HasPrefix(name, "passwords_") {
			continue
		}

		v, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		list, ok := v["default"].(map[string]interface{})
		if !ok {
			continue
		}

		for i := range list {
			list[i] = "..."
		}
	}
}
