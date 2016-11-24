package softlayer_test

import (
	"io/ioutil"
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
	"koding/kites/kloud/stack/provider/providertest"
	"koding/kites/kloud/userdata"
)

var minimumTemplate = `
{
	"resource": {
		"softlayer_virtual_guest": {
			"test": {
				"name": "test"
			}
		}
	}
}
`

func newBaseStack(template string) (*provider.BaseStack, error) {
	t, err := provider.ParseTemplate(template, nil)
	if err != nil {
		return nil, err
	}

	s := &provider.BaseStack{
		Provider: softlayer.Provider,
		Req: &kite.Request{
			Username: "test",
		},
		Session: &session.Session{
			Userdata: &userdata.Userdata{
				KlientURL: "https://test.com/klient.gz",
				Keycreator: &keycreator.Key{
					KontrolURL:        "https://test.com/kontrol/kite",
					KontrolPrivateKey: testkeys.Private,
					KontrolPublicKey:  testkeys.Public,
				},
			},
		},
		Keys: &publickeys.Keys{
			PublicKey: "random-publickey",
		},
		Builder: &provider.Builder{
			Template: t,
		},
		KlientIDs: make(stack.KiteMap),
	}
	return s, nil
}

func TestVerifyCredential(t *testing.T) {
	bs, _ := newBaseStack(minimumTemplate)
	s := &softlayer.Stack{BaseStack: bs}

	c := &stack.Credential{
		Credential: &softlayer.Credential{
			Username: os.Getenv("SL_USERNAME"),
			ApiKey:   os.Getenv("SL_API_KEY"),
		},
	}

	if err := s.VerifyCredential(c); err != nil {
		t.Fatal(err)
	}
}

func TestBootstrapTemplates(t *testing.T) {
	bs, _ := newBaseStack(minimumTemplate)
	s := &softlayer.Stack{BaseStack: bs}

	c := &stack.Credential{
		Credential: &softlayer.Credential{
			Username: os.Getenv("SL_USERNAME"),
			ApiKey:   os.Getenv("SL_API_KEY"),
		},
	}

	_, err := s.BootstrapTemplates(c)
	if err != nil {
		t.Fatal(err)
	}
}

func stripNondeterministicResources(s string) string {
	if s == "user_data" {
		return "***"
	}

	return ""
}

func TestApplyTemplate(t *testing.T) {
	cases := map[string]struct {
		stack string
		want  string
	}{
		"single guest stack": {
			"testdata/single-guest.json",
			"testdata/single-guest.json.golden",
		},
	}

	c := &stack.Credential{
		Credential: &softlayer.Credential{
			Username: os.Getenv("SL_USERNAME"),
			ApiKey:   os.Getenv("SL_API_KEY"),
		},
		Bootstrap: &softlayer.Bootstrap{
			KeyID: "12345",
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			pStack, err := ioutil.ReadFile(cas.stack)
			if err != nil {
				t.Fatal(err)
			}

			pWant, err := ioutil.ReadFile(cas.want)
			if err != nil {
				t.Fatal(err)
			}

			bs, _ := newBaseStack(string(pStack))
			s := &softlayer.Stack{BaseStack: bs}

			stack, err := s.ApplyTemplate(c)
			if err != nil {
				t.Fatal(err)
			}

			if err := providertest.Equal(stack.Content, string(pWant), stripNondeterministicResources); err != nil {
				t.Fatal(err)
			}
		})
	}
}
