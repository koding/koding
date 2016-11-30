package stack_test

import (
	"encoding/json"
	"reflect"
	"testing"

	"koding/klientctl/kloud/stack"

	"github.com/hashicorp/hcl"
)

var awsStackHCL = []byte(`provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
}

resource "aws_instance" "example-instance" {
	instance_type = "t2.nano"
	ami = ""
	tags {
		Name = "${var.koding_user_username}-${var.koding_group_slug}"
	}
	user_data = "echo \"hello world!\" >> /helloworld.txt"
}`)

var awsStackJSON = []byte(`{
	"provider": {
		"aws": {
			"access_key": "${var.aws_access_key}",
			"secret_key": "${var.aws_secret_key}"
		}
	},
	"resource": {
		"aws_instance": {
			"example-instance": {
				"instance_type": "t2.nano",
				"ami": "",
				"tags": {
					"Name": "${var.koding_user_username}-${var.koding_group_slug}"
				},
				"user_data": "echo \"hello world!\" >> /helloworld.txt"
			}
		}
	}
}`)

var awsStack = map[string]interface{}{
	"provider": map[string]interface{}{
		"aws": map[string]interface{}{
			"access_key": "${var.aws_access_key}",
			"secret_key": "${var.aws_secret_key}",
		},
	},
	"resource": map[string]interface{}{
		"aws_instance": map[string]interface{}{
			"example-instance": map[string]interface{}{
				"instance_type": "t2.nano",
				"ami":           "",
				"tags": map[string]interface{}{
					"Name": "${var.koding_user_username}-${var.koding_group_slug}",
				},
				"user_data": "echo \"hello world!\" >> /helloworld.txt",
			},
		},
	},
}

func TestFixHCL(t *testing.T) {
	var vHCL interface{}

	if err := hcl.Unmarshal(awsStackHCL, &vHCL); err != nil {
		t.Fatalf("hcl.Unmarshal()=%s", err)
	}

	if testing.Verbose() {
		t.Logf("original (vHCL):\n%s", mustJSON(vHCL))
	}

	if reflect.DeepEqual(vHCL, awsStack) {
		t.Fatal("expected HCL-encoded stack to not unmarshal cleanly")
	}

	stack.FixHCL(vHCL)

	if !reflect.DeepEqual(vHCL, awsStack) {
		t.Fatalf("got %+v, want %+v", vHCL, awsStack)
	}

	var vJSON interface{}

	if err := json.Unmarshal(awsStackJSON, &vJSON); err != nil {
		t.Fatalf("json.Unmarshal()=%s", err)
	}

	if testing.Verbose() {
		t.Logf("fixed (vJSON):\n%s", mustJSON(vJSON))
	}

	if !reflect.DeepEqual(vJSON, vHCL) {
		t.Fatalf("got %+v, want %+v", vJSON, vHCL)
	}
}

func mustJSON(v interface{}) []byte {
	p, err := json.MarshalIndent(v, "", "\t")
	if err != nil {
		panic(err)
	}

	return p
}
