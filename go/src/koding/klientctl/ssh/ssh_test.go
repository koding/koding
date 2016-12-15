package ssh

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/koding/sshkey"
)

func TestSSHGenerateOK(t *testing.T) {
	dir, err := ioutil.TempDir("", "ssh")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(dir)

	pubPath, privPath, err := KeyPaths(dir)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	pubKey, _, err := GenerateSaved(pubPath, privPath)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if _, err := os.Stat(filepath.Join(dir, DefaultKeyName)); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if _, err := os.Stat(filepath.Join(dir, DefaultKeyName) + ".pub"); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	pk, err := PublicKey(pubPath)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if pk != pubKey {
		t.Fatalf("want public key = %s; got %s", pubKey, pk)
	}
}

func TestSSHGenerateCustomName(t *testing.T) {
	dir, err := ioutil.TempDir("", "ssh")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(dir)

	customName := filepath.Join(dir, "custom")
	pubKey, privKey, err := sshkey.Generate()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := ioutil.WriteFile(customName, []byte(privKey), 0600); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if err := ioutil.WriteFile(customName+".pub", []byte(pubKey), 0600); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	pubPath, privPath, err := KeyPaths(customName)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if _, _, err := GenerateSaved(pubPath, privPath); err == nil {
		t.Fatalf("want err != nil; got <nil>")
	}

	pubPathNonExist, _, err := KeyPaths(dir)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if _, err := PublicKey(pubPathNonExist); err == nil {
		t.Fatalf("want err != nil; got <nil>")
	}

	pk, err := PublicKey(pubPath)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if pk != pubKey {
		t.Fatalf("want public key = %s; got %s", pubKey, pk)
	}
}
