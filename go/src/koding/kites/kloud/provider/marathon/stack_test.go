package marathon_test

import (
	"io/ioutil"
	"regexp"
	"testing"

	"koding/kites/config"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/provider/marathon"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/stack/provider/providertest"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/kite/testkeys"
	"github.com/koding/logging"
)

func init() {
	stack.Konfig = &config.Konfig{}
}

// stripNondeterministicResources sets the following fields to "...",
// as they change between test runs:
//
//   - resource.marathon_app.*.env.KODING_METADATA_#
//
func stripNondeterministicResources(s string) string {
	if matched, _ := regexp.MatchString("KODING_METADATA_[0-9]", s); matched {
		return "***"
	}

	return ""
}

func TestApplyTemplate(t *testing.T) {
	log := logging.NewCustom("test", true)

	cred := &stack.Credential{
		Identifier: "ident",
		Credential: &marathon.Credential{URL: "http://127.0.0.1:8080"},
	}

	cases := map[string]struct {
		stack  string
		want   string
		labels []marathon.Label
	}{
		"single app stack": {
			"testdata/single-app.json",
			"testdata/single-app.json.golden",
			[]marathon.Label{
				{Label: "/app", AppID: "/app-foobar-ident"},
			},
		},
		"multi app stack": {
			"testdata/multi-app.json",
			"testdata/multi-app.json.golden",
			[]marathon.Label{
				{Label: "/multi-app-1", AppID: "/multi-app/multi-app-foobar-ident-1"},
				{Label: "/multi-app-2", AppID: "/multi-app/multi-app-foobar-ident-2"},
				{Label: "/multi-app-3", AppID: "/multi-app/multi-app-foobar-ident-3"},
			},
		},
		"multi container stack": {
			"testdata/multi-container.json",
			"testdata/multi-container.json.golden",
			[]marathon.Label{
				{Label: "/multi-app-1", AppID: "/multi-app-foobar-ident"},
				{Label: "/multi-app-2", AppID: "/multi-app-foobar-ident"},
				{Label: "/multi-app-3", AppID: "/multi-app-foobar-ident"},
			},
		},
		"multi app multi container stack": {
			"testdata/multi-app-multi-container.json",
			"testdata/multi-app-multi-container.json.golden",
			[]marathon.Label{
				{Label: "/multi-app-1-1", AppID: "/multi-app/multi-app-foobar-ident-1"},
				{Label: "/multi-app-1-2", AppID: "/multi-app/multi-app-foobar-ident-1"},
				{Label: "/multi-app-1-3", AppID: "/multi-app/multi-app-foobar-ident-1"},
				{Label: "/multi-app-2-1", AppID: "/multi-app/multi-app-foobar-ident-2"},
				{Label: "/multi-app-2-2", AppID: "/multi-app/multi-app-foobar-ident-2"},
				{Label: "/multi-app-2-3", AppID: "/multi-app/multi-app-foobar-ident-2"},
				{Label: "/multi-app-3-1", AppID: "/multi-app/multi-app-foobar-ident-3"},
				{Label: "/multi-app-3-2", AppID: "/multi-app/multi-app-foobar-ident-3"},
				{Label: "/multi-app-3-3", AppID: "/multi-app/multi-app-foobar-ident-3"},
			},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			pStack, err := ioutil.ReadFile(cas.stack)
			if err != nil {
				t.Fatalf("ReadFile()=%s", err)
			}

			pWant, err := ioutil.ReadFile(cas.want)
			if err != nil {
				t.Fatalf("ReadFile()=%s", err)
			}

			template, err := provider.ParseTemplate(string(pStack), log)
			if err != nil {
				t.Fatalf("ParseTemplate()=%s", err)
			}

			s := &marathon.Stack{
				BaseStack: &provider.BaseStack{
					Arg: &stack.ApplyRequest{
						GroupName: "foobar",
					},
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
				EntrypointBaseURL: "$ENTRYPOINT_URL",
				ScreenURL:         "$SCREEN_URL",
				CertURL:           "$CERT_URL",
				KlientURL:         "$KLIENT_URL",
			}

			stack, err := s.ApplyTemplate(cred)
			if err != nil {
				t.Fatalf("ApplyTemplate()=%s", err)
			}

			if err := providertest.Equal(stack.Content, string(pWant), stripNondeterministicResources); err != nil {
				t.Fatal(err)
			}

			if !reflect.DeepEqual(s.Labels, cas.labels) {
				t.Fatalf("got %#v, want %#v", s.Labels, cas.labels)
			}
		})
	}
}
