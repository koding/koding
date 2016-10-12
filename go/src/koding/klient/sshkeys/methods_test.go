package sshkeys

import (
	"flag"
	"koding/klient/testutil"
	"log"
	"os"
	"os/user"
	"strings"
	"testing"

	"github.com/koding/kite"
)

var exampleKey = struct {
	Key         string
	Fingerprint string
}{
	Key:         "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwhQ3QB/4xtgpVYQVOoogNxz+3L3bjUuoOP/1duR9JxzLL0maxV64lVyLxLw14G+tG0JS42vtkySX9VzQRWofQlRNK5YdAtBQY7Xl/bWvjtXU/oI9F8o59cTkEduG4UC8nqGlMcabvD3+YnkF1HOxLnkDa+MfnTjA/+SlpJYFFzXfgKbiOSBZFie/nb+KY/40YJ74V9QGpY8qPxWct4pjopcgE2mEigZLc5UgCUNmRfYWvqqevLeph0fqXWliYtLQcTLpoZIVscK8fPXkHPKcopMVnqc9Z+vTW02qniLgPV1HCzPBTWynEZ6a51fVrqraRlDVeEruMJZZEjp33YD71 klient@example.com",
	Fingerprint: "5d:30:cd:3f:f3:60:64:ea:1d:f1:cc:7f:06:23:11:f0",
}

var (
	sshkeys *kite.Kite

	// remote defines a remote user calling the sshkeys kite
	remote *kite.Client
)

func TestMain(m *testing.M) {
	flag.Parse()
	kiteURL := testutil.GenKiteURL()

	sshkeys = kite.New("sshkeys", "0.0.1")
	sshkeys.Config.DisableAuthentication = true
	sshkeys.Config.Port = kiteURL.Port()
	sshkeys.HandleFunc("list", List)
	sshkeys.HandleFunc("add", Add)
	sshkeys.HandleFunc("delete", Delete)

	go sshkeys.Run()
	<-sshkeys.ServerReadyNotify()
	defer sshkeys.Close()

	u, err := user.Current()
	if err != nil {
		panic(err)
	}

	remoteKite := kite.New("remote", "0.0.1")
	remoteKite.Config.Username = u.Username
	remote = remoteKite.NewClient(kiteURL.String())
	err = remote.Dial()
	if err != nil {
		log.Fatalf("err")
	}
	defer remoteKite.Close()

	os.Exit(m.Run())
}

func TestAdd(t *testing.T) {
	resp, err := remote.Tell("add", struct {
		Keys []string
	}{
		Keys: []string{exampleKey.Key},
	})

	if err != nil {
		t.Fatal(err)
	}

	b, err := resp.Bool()
	if err != nil {
		t.Fatal(err)
	}

	if !b {
		t.Error("add method should return true, got false")
	}
}

func TestList(t *testing.T) {
	resp, err := remote.Tell("list")
	if err != nil {
		t.Fatal(err)
	}

	var r map[string]string
	if err := resp.Unmarshal(&r); err != nil {
		t.Fatal(err)
	}

	key, ok := r[exampleKey.Fingerprint]
	if !ok {
		t.Errorf("list: couldn't find key with fingerprint %s", exampleKey.Fingerprint)
	}

	if key != exampleKey.Key {
		t.Errorf("list: added key is not equal. \nGot: %v\nWant: %s\n", key, exampleKey.Key)
	}
}

func TestDelete(t *testing.T) {
	resp, err := remote.Tell("delete", struct {
		Fingerprints []string
	}{
		Fingerprints: []string{exampleKey.Fingerprint},
	})

	if err != nil {
		t.Fatal(err)
	}

	b, err := resp.Bool()
	if err != nil {
		t.Fatal(err)
	}

	if !b {
		t.Error("delete method should return true, got false")
	}

	resp, err = remote.Tell("list")
	if strings.Contains(err.Error(), "no ssh keys found") {
		// means the authorized_keys is totally empty right now, we can skip the test
		// immediately
		t.SkipNow()
	}

	if err != nil {
		t.Fatal(err)
	}

	var r map[string]string
	if err := resp.Unmarshal(&r); err != nil {
		t.Fatal(err)
	}

	_, ok := r[exampleKey.Fingerprint]
	if ok {
		t.Errorf("delete: key for '%s still exists after deletion'", exampleKey.Fingerprint)
	}
}
