package marathon_test

import (
	"encoding/json"
	"fmt"
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

var basicStack = `{
  "resource": {
    "marathon_app": {
      "app": {
        "app_id": "/app",
        "cmd": "python3 -m http.server 8080",
        "container": {
          "docker": [
            {
              "image": "python:3",
              "network": "BRIDGE"
            }
          ]
        },
        "cpus": 1.2,
        "mem": 256
      }
    }
  }
}`

var appliedBasicStack = `{
  "resource": {
    "marathon_app": {
      "app": {
        "app_id": "/app",
        "cmd": "/mnt/mesos/sandbox/entrypoint.${count.index + 1}.sh python3 -m http.server 8080",
        "container": [
          {
            "docker": [
              {
                "image": "python:3",
                "network": "BRIDGE",
                "port_mappings": {
                  "port_mapping": [
                    {
                      "container_port": 56789,
                      "host_port": 0,
                      "protocol": "tcp"
                    }
                  ]
                }
              }
            ]
          }
        ],
        "count": 1,
        "cpus": 1.2,
        "env": {
          "KODING_KLIENT_URL": "",
          "KODING_METADATA_1": "..."
        },
        "fetch": [
          {
            "executable": true,
            "uri": "/entrypoint.1.sh"
          }
        ],
        "health_checks": {
          "health_check": [
            {
              "command": {
                "value": "curl -f -X GET http://$$HOST:$${PORT_56789}/kite"
              },
              "max_consecutive_failures": 3,
              "protocol": "COMMAND"
            }
          ]
        },
        "mem": 256
      }
    }
  }
}`

func TestApplyTemplate(t *testing.T) {
	log := logging.NewCustom("test", true)

	cred := &stack.Credential{
		Credential: &marathon.Credential{URL: "http://127.0.0.1:8080"},
	}

	cases := map[string]struct {
		stack string
		want  string
	}{
		"basic stack": {
			basicStack,
			appliedBasicStack,
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			template, err := provider.ParseTemplate(cas.stack, log)
			if err != nil {
				t.Fatalf("ParseTemplate()=%s", err)
			}

			s := &marathon.Stack{
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

			if err := equal(stack.Content, cas.want); err != nil {
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
