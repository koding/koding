package softlayer_test

import (
	// "fmt"
	"os"
	"testing"

	"github.com/koding/kite"
	"github.com/koding/kite/testkeys"

	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/provider/softlayer"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"
)

var baseTemplate = `
{
  "provider": {
    "softlayer": {
      "username": "${var.username}",
      "api_key": "${var.api_key}"
    }
  },
  "output": {
    "key_id": {
      "value": "${softlayer_ssh_key.koding_ssh_key.id}"
    },
    "key_fingerprint": {
      "value": "${softlayer_ssh_key.koding_ssh_key.fingerprint}"
    }
  },
  "resource": {
    "softlayer_ssh_key": {
      "koding_ssh_key": {
        "name": "${var.key_name}",
        "public_key": "${var.public_key}"
      }
    },
		"softlayer_virtual_guest": {
			"softlayer-vg": {
				"name": "softlayer-vg",
				"domain": "koding.com",
				"ssh_keys": ["${softlayer_ssh_key.koding_ssh_key.id}"],
				"machine_type": "t2.micro",
				"image": "UBUNTU-14-64",
				"region": "dal09",
				"public_network_speed": 10,
				"cpu": 1,
				"ram": 1024
			}
		}
  },
  "variable": {
    "key_name": {
      "default": "{{.KeyName}}"
    },
    "public_key": {
      "default": "{{.PublicKey}}"
    }
  }
}
`

func newBaseStack() (*provider.BaseStack, error) {
	t, err := provider.ParseTemplate(baseTemplate, nil)
	if err != nil {
		return nil, err
	}

	s := &provider.BaseStack{
		Provider: softlayer.Provider,
		Req: &kite.Request{
			Username: "testuser",
		},
		Arg: &stack.BootstrapRequest{
			Provider:  "softlayer",
			GroupName: "testgroup",
		},
		Keys: &publickeys.Keys{
			PublicKey: "random-publickey",
		},
		Builder: &provider.Builder{
			Template: t,
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
	}
	return s, nil
}

func TestNewBaseStack(t *testing.T) {
	_, err := newBaseStack()
	if err != nil {
		t.Fatal(err)
	}
}

func TestVerifyCredential(t *testing.T) {
	bs, _ := newBaseStack()
	s := &softlayer.Stack{BaseStack: bs}

	c := &stack.Credential{
		Credential: &softlayer.Credential{
			Username: os.Getenv("SL_USERNAME"),
			ApiKey: os.Getenv("SL_API_KEY"),
		},
	}

	if err := s.VerifyCredential(c); err != nil {
		t.Fatal(err)
	}
}

func TestBootstrapTemplates(t *testing.T) {
	bs, _ := newBaseStack()
	s := &softlayer.Stack{BaseStack: bs}

	c := &stack.Credential{
		Credential: &softlayer.Credential{
			Username: os.Getenv("SL_USERNAME"),
			ApiKey: os.Getenv("SL_API_KEY"),
		},
	}

	_, err := s.BootstrapTemplates(c)
	if err != nil {
		t.Fatal(err)
	}
}

func TestApplyTemplate(t *testing.T) {
	bs, _ := newBaseStack()
	s := &softlayer.Stack{BaseStack: bs}

	c := &stack.Credential{
		Credential: &softlayer.Credential{
			Username: os.Getenv("SL_USERNAME"),
			ApiKey: os.Getenv("SL_API_KEY"),
		},
		Bootstrap: &softlayer.Bootstrap{
			KeyID: "123456789",
			KeyFingerprint: "aa:bb:cc:dd:ee:ff",
		},
	}

	_, err := s.ApplyTemplate(c)
	if err != nil {
		t.Fatal(err)
	}
}
