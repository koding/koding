package vagrantutil

import (
	"fmt"
	"log"
	"os"
	"testing"

	"github.com/hashicorp/go-version"
	"github.com/koding/logging"
)

const testVagrantFile = `# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "vagrant"

  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "1024", "--cpus", "1"]
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

	vg.Log = logging.NewLogger("vagrantutil_test")
	vg.Log.SetLevel(logging.DEBUG)
	h := logging.NewWriterHandler(os.Stderr)
	h.SetLevel(logging.DEBUG)
	vg.Log.SetHandler(h)

	ret := m.Run()
	os.RemoveAll(vagrantName)
	os.Exit(ret)
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

func TestBoxAddRemove(t *testing.T) {
	box := &Box{
		Name:    "rjeczalik/dummy",
		Version: "1.0.0",
	}
	vg.BoxRemove(box) // remove if already exists

	out, err := vg.BoxAdd(box)
	if err != nil {
		t.Fatal(err)
	}

	testOutput(t, "vagrant box add", out)

	if err = Wait(vg.BoxAdd(box)); err != ErrBoxAlreadyExists {
		t.Errorf("want err=%v, got %v", ErrBoxAlreadyExists, err)
	}

	badBox := &Box{
		Name:    "rjeczalik/dummy",
		Version: ".abc",
	}
	if err = Wait(vg.BoxAdd(badBox)); err != ErrBoxInvalidVersion {
		t.Errorf("want err=%v, git %v", ErrBoxInvalidVersion, err)
	}

	badBox = &Box{
		Name:    "rjeczalik/nonexisting",
		Version: "1.0.0",
	}
	if err = Wait(vg.BoxAdd(badBox)); err != ErrBoxNotAvailable {
		t.Errorf("want err=%v, git %v", ErrBoxNotAvailable, err)
	}

	out, err = vg.BoxRemove(box)
	if err != nil {
		t.Fatal(err)
	}

	testOutput(t, "vagrant box remove", out)
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

	testOutput(t, "vagrant up", out)

	status, err := vg.Status()
	if err != nil {
		t.Fatal(err)
	}

	if status != Running {
		t.Errorf("Vagrant status should be: %s. Got: %s", Running, status)
	}
}

func TestSSH(t *testing.T) {
	out, err := vg.SSH("ifconfig -a")
	if err != nil {
		t.Fatal(err)
	}

	testOutput(t, "vagrant ssh", out)
}

func TestHalt(t *testing.T) {
	out, err := vg.Halt()
	if err != nil {
		t.Fatal(err)
	}

	testOutput(t, "vagrant halt", out)

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

func TestBoxList(t *testing.T) {
	boxes, err := vg.BoxList()
	if err != nil {
		t.Fatal(err)
	}

	if len(boxes) == 0 {
		t.Fatal("want at least one box, got none")
	}

	for i, box := range boxes {
		if box.Name == "" {
			t.Errorf("%d: empty box name", i)
		}
		if box.Provider == "" {
			t.Errorf("%d: empty box provider", i)
		}
		if box.Version == "" {
			t.Errorf("%d: empty box version", i)
		}
	}
}

func TestDestroy(t *testing.T) {
	out, err := vg.Destroy()
	if err != nil {
		t.Fatal(err)
	}

	testOutput(t, "vagrant destroy", out)

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

func testOutput(t *testing.T, cmd string, out <-chan *CommandOutput) {
	for res := range out {
		if res.Error != nil {
			t.Error(res.Error)
		}
	}
}
