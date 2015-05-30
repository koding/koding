package webhook

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestPayloads(t *testing.T) {
	for name, typ := range payloads {
		path := filepath.Join("testdata", name+".json")
		f, err := os.Open(path)
		if err != nil {
			t.Fatalf("Open(%q)=%v", path, err)
		}
		err = json.NewDecoder(f).Decode(reflect.New(typ).Interface())
		f.Close()
		if err != nil {
			t.Errorf("failed to unmarshal %q: %v", path, err)
		}
	}
}
