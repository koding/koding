package do

import (
	"fmt"
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

	wantTemplate = fmt.Sprintf(wantTemplate, st.(*Stack).keyName(), bs.Keys.PublicKey)
	gotTemplate := templates[0].Content

	if gotTemplate != wantTemplate {
		t.Errorf("result template doesn't match.\nwant:\n%s\ngot :\n%s\n",
			wantTemplate, gotTemplate)
	}
}

func TestStack_ApplyTemplate(t *testing.T) {
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
		Bootstrap: &Bootstrap{
			KeyFingerprint: "aa:bb:cc",
			KeyID:          "56789",
		},
	}

	// we just run the function to catch any c
	_, err = st.ApplyTemplate(cred)
	if err != nil {
		t.Fatal(err)
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
		Provider: doProvider,
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
