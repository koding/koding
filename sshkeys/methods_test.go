package sshkeys

import (
	"log"
	"os/user"
	"testing"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

const examplePublicKey = `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwhQ3QB/4xtgpVYQVOoogNxz+3L3bjUuoOP/1duR9JxzLL0maxV64lVyLxLw14G+tG0JS42vtkySX9VzQRWofQlRNK5YdAtBQY7Xl/bWvjtXU/oI9F8o59cTkEduG4UC8nqGlMcabvD3+YnkF1HOxLnkDa+MfnTjA/+SlpJYFFzXfgKbiOSBZFie/nb+KY/40YJ74V9QGpY8qPxWct4pjopcgE2mEigZLc5UgCUNmRfYWvqqevLeph0fqXWliYtLQcTLpoZIVscK8fPXkHPKcopMVnqc9Z+vTW02qniLgPV1HCzPBTWynEZ6a51fVrqraRlDVeEruMJZZEjp33YD71 klient@example.com`

var (
	sshkeys *kite.Kite

	// remote defines a remote user calling the sshkeys kite
	remote *kite.Client
)

func init() {
	sshkeys = kite.New("sshkeys", "0.0.1")
	sshkeys.Config.DisableAuthentication = true
	sshkeys.Config.Port = 3636
	sshkeys.HandleFunc("list", List)
	sshkeys.HandleFunc("add", Add)
	sshkeys.HandleFunc("delete", Delete)

	go sshkeys.Run()
	<-sshkeys.ServerReadyNotify()

	u, err := user.Current()
	if err != nil {
		panic(err)
	}

	remoteKite := kite.New("remote", "0.0.1")
	remoteKite.Config.Username = u.Username
	remote = remoteKite.NewClient("http://127.0.0.1:3636/kite")
	err = remote.Dial()
	if err != nil {
		log.Fatal("err")
	}
}

func TestAdd(t *testing.T) {
	resp, err := remote.Tell("add", struct {
		Keys []string
	}{
		Keys: []string{examplePublicKey},
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
