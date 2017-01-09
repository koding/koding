package main

import (
	"bytes"
	"encoding/json"
	"os"
	"reflect"
	"testing"

	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/stack"
	"koding/klientctl/endpoint/stack/stackfixture"
)

func TestStackCreate(t *testing.T) {
	cases := map[string]struct {
		tmpl []byte
		cred string
		resp *stack.ImportResponse
	}{
		"a yaml template": {
			stackfixture.StackYAML,
			"587265a0bbc81e01cd2f849b",
			&stack.ImportResponse{
				TemplateID: "5870035a50368f142b105e9f",
				StackID:    "587003e6d90a2a0a2bc4f385",
				Title:      "TestStackCreate credential",
			},
		},
		"a json template": {
			stackfixture.StackJSON,
			"587265adbbc81e01cd2f849c",
			&stack.ImportResponse{
				TemplateID: "5870035a50368f142b105ea4",
				StackID:    "53925a609b76835748c0c4fd",
				Title:      "TestStackCreate credential",
			},
		},
		"a hcl template": {
			stackfixture.StackHCL,
			"587265b7bbc81e01cd2f849d",
			&stack.ImportResponse{
				TemplateID: "587003e6d90a2a0a2bc4f384",
				StackID:    "587003b2d90a2a0a2bc4f380",
				Title:      "TestStackCreate credential",
			},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			var buf bytes.Buffer

			cmd := &MainCmd{
				Stdin:  bytes.NewReader(cas.tmpl),
				Stderr: os.Stderr,
				Stdout: &buf,
			}
			defer cmd.Close()

			cmd.FT.Add("import", cas.resp)

			if err := addCredential(cmd, cas.cred); err != nil {
				t.Fatalf("addCredential()=%s", err)
			}

			err := cmd.Run("stack", "create",
				"--file", "-",
				"--json",
			)

			if err != nil {
				t.Fatalf("Run()=%s", err)
			}

			var got stack.ImportResponse

			if err := json.Unmarshal(buf.Bytes(), &got); err != nil {
				t.Fatalf("Unmarshal()=%s", err)
			}

			if !reflect.DeepEqual(&got, cas.resp) {
				t.Fatalf("got %#v, want %#v", &got, cas.resp)
			}
		})
	}
}

func addCredential(cmd *MainCmd, identifier string) error {
	c := cmd.New()

	p, err := json.Marshal(&aws.Cred{
		AccessKey: "***",
		SecretKey: "***",
		Region:    "us-east-1",
	})
	if err != nil {
		return err
	}

	c.Stdin = bytes.NewReader(p)
	c.Stderr = os.Stderr
	c.Stdout = os.Stderr

	c.FT.Add("credential.add", &stack.CredentialItem{
		Identifier: identifier,
		Title:      "TestStackCreate credential",
		Team:       "foobar",
	})

	return nonil(
		c.Run("credential", "create",
			"--provider", "aws",
			"--team", "foobar",
			"--file", "-",
		),
		c.Run("credential", "use", identifier),
	)
}
