package container

import (
	"fmt"
	"net"
	"os"
	"testing"
)

const (
	ContainerName = "testContainer"
	ContainerType = "busybox"
	PrepareHost   = "vagrant"
	PrepareName   = "vm-test"
)

func exist(filename string) bool {
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		return false
	}

	return true
}

func TestNewContainer(t *testing.T) {
	c := NewContainer(ContainerName)

	if c.Name != ContainerName {
		t.Errorf("NewContainer: exptecting: %s got: %s", ContainerName, c.Name)
	}

	containerDir := lxcDir + ContainerName + "/"

	if c.Path("") != containerDir {
		t.Errorf("NewContainer: exptecting: %s got: %s", containerDir, c.Dir)
	}

}

func TestContainer_GenerateFiles(t *testing.T) {
	c := NewContainer(ContainerName)
	c.IP = net.ParseIP("127.0.0.1")
	c.HostnameAlias = "vagrant"

	if err := c.AsHost().PrepareDir(c.Path("")); err != nil {
		t.Errorf("Generatefile: %s ", err)
	}

	var files = []struct {
		fileName string
		template string
	}{
		{c.Path("config"), "config"},
		{c.Path("fstab"), "fstab"},
		{c.Path("ip-address"), "ip-address"},
	}

	for _, file := range files {
		err := c.AsHost().GenerateFile(file.fileName, file.template)
		if err != nil {
			t.Errorf("Generatefile: %s ", err)
		}

		if !exist(file.fileName) {
			t.Errorf("Generatefile: %s does not exist", file.fileName)
		}
	}

}

func TestContainer_GenerateOverlayFiles(t *testing.T) {
	c := NewContainer(ContainerName)
	c.HostnameAlias = "vagrant"
	c.LdapPassword = "123456789"
	c.IP = net.ParseIP("127.0.0.1")

	if err := c.AsContainer().PrepareDir(c.OverlayPath("")); err != nil {
		t.Errorf("PrepareDir Overlay: %s ", err)
	}

	if err := c.AsContainer().PrepareDir(c.OverlayPath("/lost+found")); err != nil {
		t.Errorf("PrepareDir Overlay/lost+found: %s ", err)
	}

	if err := c.AsContainer().PrepareDir(c.OverlayPath("/etc")); err != nil {
		t.Errorf("PrepareDir Overlay/etc: %s ", err)
	}

	var containerFiles = []struct {
		fileName string
		template string
	}{
		{c.OverlayPath("etc/hostname"), "hostname"},
		{c.OverlayPath("etc/hosts"), "hosts"},
		{c.OverlayPath("etc/ldap.conf"), "ldap.conf"},
	}

	for _, file := range containerFiles {
		err := c.AsContainer().GenerateFile(file.fileName, file.template)
		if err != nil {
			t.Errorf("Generatefile: %s ", err)
		}

		if !exist(file.fileName) {
			t.Errorf("Generatefile: %s does not exist", file.fileName)
		}
	}
}

func TestContainer_CreateUserHome(t *testing.T) {
	c := NewContainer(ContainerName)
	c.HostnameAlias = "vagrant"
	c.LdapPassword = "123456789"
	c.IP = net.ParseIP("127.0.0.1")
	c.Username = "testing"
	c.WebHome = "testing"

	if err := c.createUserHome(); err != nil {
		t.Errorf("Could not create home directory %s ", err)
	}

	if !exist(c.Path("rootfs/home/testing")) {
		t.Error("User home directory does not exist")
	}
}

// func TestContainer_CreateWebDir(t *testing.T) {
// 	c := NewContainer(ContainerName)
// 	c.HostnameAlias = "vagrant"
// 	c.LdapPassword = "123456789"
// 	c.IP = net.ParseIP("127.0.0.1")
// 	c.Username = "testing"
// 	c.WebHome = "testing"

// 	vmWebDir := c.Path(fmt.Sprintf("rootfs/home/%s/Web", c.WebHome))

// 	if err := c.createWebDir(vmWebDir); err != nil {
// 		t.Errorf("Could not create web directory %s ", err)
// 	}

// 	if !exist(c.Path("rootfs/var/www")) {
// 		t.Error("Create web directory, /var/www does not exist")
// 	}

// 	if !exist(c.Path("rootfs/home/testing/Web")) {
// 		t.Error("Create web directory. /home/testing/Web does not exist")
// 	}
// }
