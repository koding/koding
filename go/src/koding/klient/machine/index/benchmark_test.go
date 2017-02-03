package index

import (
	"bytes"
	"encoding/json"
	"flag"
	"testing"
	"time"
)

var repo = flag.String("repo", "", "")

func TestRepo(t *testing.T) {
	if *repo == "" {
		t.Skip("missing -repo path, skipping...")
	}

	start := time.Now()
	idx, err := NewIndexFiles(*repo)
	if err != nil {
		t.Fatalf("NewIndexFiles()=%s", err)
	}
	end := time.Now()

	var buf bytes.Buffer

	if err := json.NewEncoder(&buf).Encode(idx); err != nil {
		t.Fatalf("Encode()=%s", err)
	}

	t.Logf("Index build time: %s", end.Sub(start))
	t.Logf("Index file count: %d", idx.Count(-1))
	t.Logf("Index size: %.4f MiB", float64(buf.Len())/1024/1024)
}
