package marathon_test

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"reflect"
	"strings"
	"testing"

	"koding/kites/config"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/provider/marathon"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/kite/testkeys"
	"github.com/koding/logging"
)

func init() {
	stack.Konfig = &config.Konfig{}
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

			if err := equal(stack.Content, string(pWant)); err != nil {
				t.Fatal(err)
			}

			if !reflect.DeepEqual(s.Labels, cas.labels) {
				t.Fatalf("got %#v, want %#v", s.Labels, cas.labels)
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
//   - resource.marathon_app.*.env.KODING_METADATA_#
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

	instance, ok := resource["marathon_app"].(map[string]interface{})
	if !ok {
		return
	}

	for _, v := range instance {
		vm, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		envs, ok := vm["env"].(map[string]interface{})
		if !ok {
			continue
		}

		for k := range envs {
			if strings.HasPrefix(k, "KODING_METADATA_") {
				envs[k] = "..."
			}
		}
	}
}
