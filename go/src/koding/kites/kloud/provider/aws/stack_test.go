package aws_test

import (
	"flag"
	"io/ioutil"
	"strings"
	"testing"

	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/provider/azure"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/stack/provider/providertest"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/kite/testkeys"
	"github.com/koding/logging"
)

var update = flag.Bool("update-golden", false, "Update golden files.")

func TestAzure_ApplyTemplate(t *testing.T) {
	flag.Parse()

	log := logging.NewCustom("test", true)

	cred := &stack.Credential{
		Credential: &aws.Cred{
			AccessKey: "AKIA" + strings.Repeat("x", 16),
			SecretKey: strings.Repeat("x", 40),
			Region:    "eu-central-1",
		},
		Bootstrap: &aws.Bootstrap{
			ACL:       "koding-acl",
			CidrBlock: "10.0.0.0/16",
			IGW:       "koding-igw",
			KeyPair:   "koding-kp",
			RTB:       "koding-rtb",
			SG:        "koding-sg",
			Subnet:    "koding-subnet",
			VPC:       "koding-vpc",
			AMI:       "ami-123456",
		},
	}

	cases := map[string]struct {
		stackFile string
		wantFile  string
	}{
		"single vm": {
			"testdata/single-vm.json",
			"testdata/single-vm.json.json.golden",
		},
		"multiple vms": {
			"testdata/multiple-vms.json",
			"testdata/multiple-vms.json.golden",
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			content, err := ioutil.ReadFile(cas.stackFile)
			if err != nil {
				t.Fatalf("ReadFile(%s)=%s", cas.stackFile, err)
			}

			template, err := provider.ParseTemplate(string(content), log)
			if err != nil {
				t.Fatalf("ParseTemplate()=%s", err)
			}

			s := &aws.Stack{
				BaseStack: &provider.BaseStack{
					Provider: azure.Provider,
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

			if *update {
				if err := providertest.Write(cas.wantFile, stack.Content, stripNondeterministicResources); err != nil {
					t.Fatalf("Write()=%s", err)
				}

				return
			}

			want, err := ioutil.ReadFile(cas.wantFile)
			if err != nil {
				t.Fatalf("ReadFile(%s)=%s", cas.wantFile, err)
			}

			if err := providertest.Equal(stack.Content, string(want), stripNondeterministicResources); err != nil {
				t.Fatal(err)
			}
		})
	}
}

// stripNondeterministicResources sets the following fields to "...",
// as they change between test runs:
//
//   - resource.aws__instance.*.custom_data
//   - variable.kitekeys_*.default.*
//
func stripNondeterministicResources(name string) string {
	switch name {
	case "0", "1", "2", "custom_data", "name":
		return "***"
	default:
		return ""
	}
}
