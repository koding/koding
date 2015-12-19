package vagrantutil

import (
	"fmt"
	"log"
	"os"
	"testing"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/hashicorp/go-version"
)

const testVagrantFile = `# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "vagrant"

  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2"]
  end
end
`

var (
	vg          *Vagrant
	vagrantName = "vagrantTest"
)

func TestMain(m *testing.M) {
	var err error
	vg, err = NewVagrant(vagrantName)
	if err != nil {
		log.Fatalln(err)
	}

	os.Exit(m.Run())
}

func TestVersion(t *testing.T) {
	out, err := vg.Version()
	if err != nil {
		t.Fatal(err)
	}

	// check if the output is correct
	_, err = version.NewVersion(out)
	if err != nil {
		t.Error(err)
	}
}

func TestCreate(t *testing.T) {
	err := vg.Create(testVagrantFile)
	if err != nil {
		t.Fatal(err)
	}

	if err := vg.vagrantfileExists(); err != nil {
		t.Error(err)
	}
}

func TestProvider(t *testing.T) {
	provider, err := vg.Provider()
	if err != nil {
		t.Fatal(err)
	}

	if provider != "virtualbox" {
		t.Errorf("Vagrant provider should be 'virtualbox'. Got: %s", provider)
	}
}

func TestUp(t *testing.T) {
	out, err := vg.Up()
	if err != nil {
		t.Fatal(err)
	}

	log.Printf("Starting to read the stream output of 'vagrant up':\n\n")
	for res := range out {
		if res.Error != nil {
			t.Error(err)
		}
		log.Println(res.Line)
	}

	log.Printf("\n\nStreaming is finished for 'vagrant up' command")

	status, err := vg.Status()
	if err != nil {
		t.Fatal(err)
	}

	if status != Running {
		t.Errorf("Vagrant status should be: %s. Got: %s", Running, status)
	}
}

func TestHalt(t *testing.T) {
	out, err := vg.Halt()
	if err != nil {
		t.Fatal(err)
	}

	log.Printf("Starting to read the stream output of 'vagrant halt':\n\n")
	for res := range out {
		if res.Error != nil {
			t.Error(err)
		}
		log.Println(res.Line)
	}

	log.Printf("\n\nStreaming is finished for 'vagrant halt' command")

	status, err := vg.Status()
	if err != nil {
		t.Fatal(err)
	}

	if status != PowerOff {
		t.Errorf("Vagrant status should be: %s. Got: %s", PowerOff, status)
	}
}

func TestList(t *testing.T) {
	list, err := vg.List()
	if err != nil {
		t.Fatal(err)
	}

	for i, l := range list {
		status, err := l.Status()
		if err != nil {
			if l.State != Unknown.String() {
				t.Errorf("failed state should be: Unknown, got: %s", l.State)
			}

			log.Println("continue because: ", err)
			continue
		}

		if l.State != status.String() {
			t.Errorf("internal state should be: %s, got: %s", status, l.State)
		}

		if l.VagrantfilePath == "" {
			t.Error("path should be not empty for list command")
		}

		fmt.Printf("[%d] status = %s path = %s\n", i, status, l.VagrantfilePath)
	}
}

func TestDestroy(t *testing.T) {
	out, err := vg.Destroy()
	if err != nil {
		t.Fatal(err)
	}

	log.Printf("Starting to read the stream output of 'vagrant destroy':\n\n")
	for res := range out {
		if res.Error != nil {
			t.Error(err)
		}
		log.Println(res.Line)
	}
	log.Printf("\n\nStreaming is finished for 'vagrant destroy' command")

	status, err := vg.Status()
	if err != nil {
		t.Fatal(err)
	}

	if status != NotCreated {
		t.Errorf("Vagrant status should be: %s. Got: %s", NotCreated, status)
	}

}

func TestStatus(t *testing.T) {
	status, err := vg.Status()
	if err != nil {
		t.Fatal(err)
	}

	if vg.State != status.String() {
		t.Errorf("Internal state should be: %s, got: %s", status, vg.State)
	}
}
