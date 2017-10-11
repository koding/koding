package softlayer_test

import (
	"flag"
	"io/ioutil"
	"os"
	"strconv"
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

var update = flag.Bool("update-golden", false, "Update golden files.")

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
	if os.Getenv("SL_USERNAME") == "" || os.Getenv("SL_API_KEY") == "" {
		t.Skip("missing SL_USERNAME / SL_API_KEY env vars")
	}

	bs, err := newBaseStack(minimumTemplate)
	if err != nil {
		t.Fatalf("newBaseStack()=%s", err)
	}

	s, err := softlayer.Provider.Stack(bs)
	if err != nil {
		t.Fatalf("Stack()=%s", err)
	}

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
	bs, err := newBaseStack(minimumTemplate)
	if err != nil {
		t.Fatalf("newBaseStack()=%s", err)
	}

	s, err := softlayer.Provider.Stack(bs)
	if err != nil {
		t.Fatalf("Stack()=%s", err)
	}

	bs.SSHKeyPairFunc(&stack.SSHKeyPair{})

	c := &stack.Credential{
		Credential: &softlayer.Credential{
			Username: os.Getenv("SL_USERNAME"),
			ApiKey:   os.Getenv("SL_API_KEY"),
		},
	}

	_, err = s.BootstrapTemplates(c)
	if err != nil {
		t.Fatal(err)
	}
}

func stripNondeterministicResources(s string) string {
	if s == "user_data" {
		return "***"
	}

	if _, err := strconv.Atoi(s); err == nil {
		return "***"
	}

	return ""
}

func TestApplyTemplate(t *testing.T) {
	flag.Parse()

	cases := map[string]struct {
		stack string
		want  string
	}{
		"single guest stack": {
			"testdata/single-guest.json",
			"testdata/single-guest.json.golden",
		},
		"single guest stack with custom image": {
			"testdata/single-guest-image.json",
			"testdata/single-guest-image.json.golden",
		},
		"single guest stack with custom template": {
			"testdata/single-guest-template.json",
			"testdata/single-guest-template.json.golden",
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

			if *update {
				if err := providertest.Write(cas.want, stack.Content, stripNondeterministicResources); err != nil {
					t.Fatalf("Write()=%s", err)
				}

				return
			}

			if err := providertest.Equal(stack.Content, string(pWant), stripNondeterministicResources); err != nil {
				t.Fatal(err)
			}
		})
	}
}
