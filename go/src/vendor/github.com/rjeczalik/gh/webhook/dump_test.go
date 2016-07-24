package webhook

import (
	"bytes"
	"crypto/sha1"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func hash(r io.Reader) ([]byte, error) {
	h := sha1.New()
	if _, err := io.Copy(h, r); err != nil {
		return nil, err
	}
	return h.Sum(nil), nil
}

func TestDump(t *testing.T) {
	unique := make(map[string]struct{})
	test := func(name string, p []byte, _ os.FileMode) error {
		name = filepath.Base(name)
		n := strings.IndexRune(name, '-')
		if n == -1 {
			t.Fatalf("unexpected file name: %s", name)
		}
		event := name[:n]
		if _, ok := payloads[event]; !ok {
			t.Fatalf("Dump written a file for a non-existing event: %s", event)
		}
		if _, ok := unique[event]; ok {
			t.Fatalf("duplicate file written for the %s event", event)
		}
		unique[event] = struct{}{}
		f, err := os.Open(filepath.Join("testdata", event+".json"))
		if err != nil {
			t.Fatalf("os.Open(%q)=%v", f.Name(), err)
		}
		defer f.Close()
		hexpected, err := hash(f)
		if err != nil {
			t.Fatalf("hashing %s failed: %v", f.Name(), err)
		}
		h, err := hash(bytes.NewReader(p))
		if err != nil {
			t.Errorf("hashing dumped file failed: %v", err)
		}
		if !bytes.Equal(h, hexpected) {
			t.Errorf("files %q and %q are not equal", name, f.Name())
		}
		return nil
	}
	h := &Dumper{
		Handler:   New(secret, BlanketHandler{}),
		WriteFile: test,
	}
	testHandler(t, h)
}
