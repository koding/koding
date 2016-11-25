package main

import (
	"bytes"
	"encoding/json"
	"reflect"
	"testing"

	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/provider/marathon"
	"koding/kites/kloud/stack"
)

func TestCredentialCreate(t *testing.T) {
	cases := map[string]struct {
		provider string
		data     interface{}
		reply    *stack.CredentialItem
	}{
		"aws credential": {
			"aws",
			&aws.Cred{
				AccessKey: "***",
				SecretKey: "***",
				Region:    "us-east-1",
			},
			&stack.CredentialItem{
				Identifier: "784dc86ba6a7a5ca91dc41fd74015353",
				Title:      "my credential",
				Team:       "foobar",
			},
		},
		"marathon credential": {
			"marathon",
			&marathon.Credential{
				URL:               "http://127.0.0.1",
				BasicAuthUser:     "rjeczalik",
				BasicAuthPassword: "qwerty",
			},
			&stack.CredentialItem{
				Identifier: "784dc86ba6a7a5ca91dc41fd74015353",
				Title:      "another credential",
				Team:       "foobar",
			},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			p, err := json.Marshal(cas.data)
			if err != nil {
				t.Fatalf("Marshal()=%s", err)
			}

			var buf bytes.Buffer

			cmd := &MainCmd{
				Stdin:  bytes.NewReader(p),
				Stdout: &buf,
			}

			cmd.FT.Add("credential.add", cas.reply)

			err = cmd.Run("credential", "create",
				"--provider", cas.provider,
				"--team", cas.reply.Team,
				"--title", cas.reply.Title,
				"--file", "-",
				"--json",
			)

			if err != nil {
				t.Fatalf("Run()=%s", err)
			}

			var got stack.CredentialItem

			if err := json.Unmarshal(buf.Bytes(), &got); err != nil {
				t.Fatalf("Unmarshal()=%s", err)
			}

			if !reflect.DeepEqual(&got, cas.reply) {
				t.Fatalf("got %#v, want %#v", &got, cas.reply)
			}
		})
	}
}
