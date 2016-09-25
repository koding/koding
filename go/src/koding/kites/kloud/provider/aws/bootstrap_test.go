package aws_test

import (
	"bytes"
	"encoding/json"
	"testing"

	"koding/kites/kloud/provider/aws"
)

func TestAWSBootstrap(t *testing.T) {
	var buf bytes.Buffer

	if err := aws.BootstrapTemplate().Execute(&buf, make(map[string]interface{})); err != nil {
		t.Fatalf("Execute()=%s", err)
	}

	var v map[string]interface{}

	if err := json.NewDecoder(&buf).Decode(&v); err != nil {
		t.Fatalf("Decode()=%s", err)
	}
}
