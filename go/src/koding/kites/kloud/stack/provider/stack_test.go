package provider_test

import (
	"flag"
	"io/ioutil"
	"path"
	"path/filepath"
	"strings"
	"testing"

	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/provider/azure"
	"koding/kites/kloud/provider/google"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/stack/provider/providertest"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/kite/testkeys"
)

var update = flag.Bool("update-golden", false, "Update golden files.")

var cases = map[string]struct {
	provider  *provider.Provider
	cred      *stack.Credential
	build     func(*provider.BaseStack) stack.Stacker
	templates []string
}{
	"aws": {
		provider: aws.Provider,
		cred: &stack.Credential{
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
		},
		build: func(bs *provider.BaseStack) stack.Stacker {
			return &aws.Stack{
				BaseStack: bs,
			}
		},
		templates: []string{
			"testdata/aws-single-vm.json",
			"testdata/aws-multiple-vms.json",
		},
	},
	"azure": {
		provider: azure.Provider,
		cred: &stack.Credential{
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
		},
		build: func(bs *provider.BaseStack) stack.Stacker {
			return &azure.Stack{
				BaseStack: bs,
			}
		},
		templates: []string{
			"testdata/azure-basic-stack-count-3.json",
			"testdata/azure-basic-stack.json",
			"testdata/azure-custom-endpoint.json",
		},
	},
	"google": {
		provider: google.Provider,
		cred: &stack.Credential{
			Credential: &google.Cred{
				Credentials: "{}",
				Project:     "koding",
				Region:      "us-east1",
			},
			Bootstrap: &google.Bootstrap{
				KodingNetworkID: "id-12345",
			},
		},
		build: func(bs *provider.BaseStack) stack.Stacker {
			return &google.Stack{
				BaseStack: bs,
			}
		},
		templates: []string{
			"testdata/google-single-vm.json",
			"testdata/google-multiple-vms.json",
		},
	},
}

func TestAzure_ApplyTemplate(t *testing.T) {
	flag.Parse()

	for name, cas := range cases {
		for _, tmpl := range cas.templates {
			t.Run(name+"/"+path.Base(tmpl), func(t *testing.T) {
				content, err := ioutil.ReadFile(filepath.FromSlash(tmpl))
				if err != nil {
					t.Fatalf("ReadFile(%s)=%s", tmpl, err)
				}

				template, err := provider.ParseTemplate(string(content), log)
				if err != nil {
					t.Fatalf("ParseTemplate()=%s", err)
				}

				s := cas.build(&provider.BaseStack{
					Provider: cas.provider,
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
					Log:       log,
					Keys: &publickeys.Keys{
						PublicKey:  testkeys.Public,
						PrivateKey: testkeys.Private,
						KeyName:    "koding",
					},
				})

				stack, err := s.ApplyTemplate(cas.cred)
				if err != nil {
					t.Fatalf("ApplyTemplate()=%s", err)
				}

				golden := filepath.FromSlash(tmpl + ".golden")

				if *update {
					if err := providertest.Write(golden, stack.Content, stripNondeterministicResources); err != nil {
						t.Fatalf("Write()=%s", err)
					}

					return
				}

				want, err := ioutil.ReadFile(golden)
				if err != nil {
					t.Fatalf("ReadFile(%s)=%s", golden, err)
				}

				if err := providertest.Equal(stack.Content, string(want), stripNondeterministicResources); err != nil {
					t.Fatal(err)
				}
			})
		}
	}
}

// stripNondeterministicResources sets the following fields to "...",
// as they change between test runs:
//
//   - resource.*_*.*.custom_data
//   - variable.kitekeys_*.default.*
//
func stripNondeterministicResources(name string) string {
	switch name {
	case "0", "1", "2", "user-data", "ssh-keys", "user_data", "custom_data", "name":
		return "***"
	default:
		return ""
	}
}
