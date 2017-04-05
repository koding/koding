package do

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"reflect"
	"strings"
	"testing"

	"github.com/koding/kite"
	"github.com/koding/kite/testkeys"
	"github.com/koding/logging"

	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"
)

func TestNewStack(t *testing.T) {
	bs, err := newDoBaseStack()
	if err != nil {
		t.Fatal(err)
	}

	_, err = newStack(bs)
	if err != nil {
		t.Fatal(err)
	}
}

func TestStack_VerifyCredential(t *testing.T) {
	bs, err := newDoBaseStack()
	if err != nil {
		t.Fatal(err)
	}

	st, err := newStack(bs)
	if err != nil {
		t.Fatal(err)
	}

	cred := &stack.Credential{
		Credential: &Credential{
			AccessToken: "12345",
		},
	}

	err = st.VerifyCredential(cred)
	if err == nil {
		t.Fatal("VerifyCredential should error in case of an invalid acces token")
	}
}

func TestStack_BootstrapTemplates(t *testing.T) {
	bs, err := newDoBaseStack()
	if err != nil {
		t.Fatal(err)
	}

	st, err := newStack(bs)
	if err != nil {
		t.Fatal(err)
	}

	st.(*Stack).sshKeyPair = &stack.SSHKeyPair{
		Name:   "test-key",
		Public: []byte("random-publickey"),
	}

	templates, err := st.BootstrapTemplates(nil)
	if err != nil {
		t.Fatal(err)
	}

	if len(templates) != 1 {
		t.Fatalf("the number of templates should be only one, got %d", len(templates))
	}

	wantTemplate := `{
  "provider": {
    "digitalocean": {
      "token": "${var.digitalocean_access_token}"
    }
  },
  "output": {
    "key_name": {
      "value": "${digitalocean_ssh_key.koding_ssh_key.name}"
    },
    "key_fingerprint": {
      "value": "${digitalocean_ssh_key.koding_ssh_key.fingerprint}"
    },
    "key_id": {
      "value": "${digitalocean_ssh_key.koding_ssh_key.id}"
    }
  },
  "resource": {
    "digitalocean_ssh_key": {
      "koding_ssh_key": {
        "name": "${var.key_name}",
        "public_key": "${var.public_key}"
      }
    }
  },
  "variable": {
    "key_name": {
      "default": "%s"
    },
    "public_key": {
      "default": "%s"
    }
  }
}
`

	wantTemplate = fmt.Sprintf(wantTemplate, st.(*Stack).sshKeyPair.Name, bs.Keys.PublicKey)
	gotTemplate := templates[0].Content

	if gotTemplate != wantTemplate {
		t.Errorf("result template doesn't match.\nwant:\n%s\ngot :\n%s\n",
			wantTemplate, gotTemplate)
	}
}

func TestStack_ApplyTemplate(t *testing.T) {
	log := logging.NewCustom("test", true)

	cred := &stack.Credential{
		Credential: &Credential{
			AccessToken: "12345",
		},
		Bootstrap: &Bootstrap{
			KeyFingerprint: "aa:bb:cc",
			KeyID:          "56789",
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
		"basic stack count 2": {
			"testdata/basic-stack-count-2.json",
			"testdata/basic-stack-count-2.json.golden",
		},
	}

	for name, cas := range cases {
		// capture range variable here
		cas := cas
		t.Run(name, func(t *testing.T) {
			t.Parallel()
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

			s := &Stack{
				BaseStack: &provider.BaseStack{
					Provider: Provider,
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

func newDoBaseStack() (*provider.BaseStack, error) {
	log := logging.NewCustom("test", true)

	testTemplate := `{
    "variable": {
        "username": {
            "default": "testuser"
        }
    },
    "provider": {
        "digitalocean": {
            "token": "${var.digitalocean_access_token}"
        }
    },
    "resource": {
        "digitalocean_droplet": {
            "example": {
                "name": "web-1",
                "image": "ubuntu-14-04-x64",
                "region": "nyc2",
                "size": "512mb",
                "user_data": "sudo apt-get install sl -y\ntouch /tmp/${var.username}.txt"
            }
        }
    }
}`

	template, err := provider.ParseTemplate(testTemplate, log)
	if err != nil {
		return nil, err
	}

	return &provider.BaseStack{
		Provider: Provider,
		Req: &kite.Request{
			Username: "testuser",
		},
		Arg: &stack.BootstrapRequest{
			Provider:  "digitalocean",
			GroupName: "testgroup",
		},
		Keys: &publickeys.Keys{
			PublicKey: "random-publickey",
		},
		Builder: &provider.Builder{
			Template: template,
		},
		Session: &session.Session{
			Userdata: &userdata.Userdata{
				KlientURL: "https://example-klient.com",
				Keycreator: &keycreator.Key{
					KontrolURL:        "https://example-kontrol.com",
					KontrolPrivateKey: testkeys.Private,
					KontrolPublicKey:  testkeys.Public,
				},
			},
		},
		KlientIDs: stack.KiteMap(map[string]string{}),
	}, nil
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
//   - resource.digitalocean_droplet.*.user_data
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

	instance, ok := resource["digitalocean_droplet"].(map[string]interface{})
	if !ok {
		return
	}

	for _, v := range instance {
		vm, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		vm["user_data"] = "..."
		vm["name"] = "..."
	}

	variable, ok := m["variable"].(map[string]interface{})
	if !ok {
		return
	}

	for name, v := range variable {
		if !strings.HasPrefix(name, "kitekeys_") {
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

	null, ok := resource["null_resource"].(map[string]interface{})
	if !ok {
		return
	}

	for _, v := range null {
		res, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		trigger, ok := res["triggers"].(map[string]interface{})
		if !ok {
			continue
		}

		trigger["user_data"] = "..."
	}
}
