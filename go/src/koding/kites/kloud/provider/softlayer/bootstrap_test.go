package softlayer_test

import (
	"bytes"
	"encoding/json"
	"testing"

	"koding/kites/kloud/provider/softlayer"
)

func TestSoftlayerBootstrap(t *testing.T) {
	var buf bytes.Buffer
	var v map[string]interface{}

	if err := softlayer.BootstrapTemplate.Execute(&buf, make(map[string]interface{})); err != nil {
		t.Fatalf("Failed to execute bootstrap template: %s", err)
	}

	if err := json.NewDecoder(&buf).Decode(&v); err != nil {
		t.Fatalf("Failed to decode buffer as json: %s", err)
	}
}
