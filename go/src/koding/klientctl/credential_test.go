package main

import (
	"bytes"
	"encoding/json"
	"os"
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
				Stderr: os.Stderr,
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

func TestCredentialDescribe(t *testing.T) {
	cases := map[string]struct {
		args  []string
		reply stack.Descriptions
		want  []*stack.Description
	}{
		"all credentials": {
			nil,
			stack.Descriptions{
				"provider 1": {Credential: []stack.Value{{Name: "key", Type: "string"}}},
				"provider 2": {Credential: []stack.Value{{Name: "token", Type: "string"}}},
			},
			[]*stack.Description{
				{Provider: "provider 1", Credential: []stack.Value{{Name: "key", Type: "string"}}},
				{Provider: "provider 2", Credential: []stack.Value{{Name: "token", Type: "string"}}},
			},
		},
		"filtered credential": {
			[]string{"--provider", "foobar"},
			stack.Descriptions{
				"provider 1": {Credential: []stack.Value{{Name: "key", Type: "string"}}},
				"provider 2": {Credential: []stack.Value{{Name: "token", Type: "string"}}},
				"foobar":     {Credential: []stack.Value{{Name: "foo", Type: "enum"}}},
			},
			[]*stack.Description{
				{Provider: "foobar", Credential: []stack.Value{{Name: "foo", Type: "enum"}}},
			},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			var buf bytes.Buffer

			cmd := &MainCmd{
				Stdout: &buf,
				Stderr: os.Stderr,
			}

			cmd.FT.Add("credential.describe", stack.CredentialDescribeResponse{Description: cas.reply})

			args := []string{"credential", "describe", "--json"}

			err := cmd.Run(append(args, cas.args...)...)
			if err != nil {
				t.Fatalf("Run()=%s", err)
			}

			var got []*stack.Description

			if err := json.Unmarshal(buf.Bytes(), &got); err != nil {
				t.Fatalf("Unmarshal()=%s", err)
			}

			if !reflect.DeepEqual(got, cas.want) {
				t.Fatalf("got %#v, want %#v", got, cas.want)
			}
		})
	}
}
