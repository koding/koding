package container

import (
	"net"
	"os"
	"testing"
)

const (
	ContainerName = "tt"
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

func TestContainer_MountRBD(t *testing.T) {
	c := NewContainer(ContainerName)
	if err := c.MountRBD(); err != nil {
		t.Errorf("Could not mount rbd '%s'", err)
	}

	mounted, err := c.CheckMount(c.OverlayPath(""))
	if err != nil {
		t.Error("Could not check mount state of overlay path", err)
	}

	if !mounted {
		t.Error("Overlay is not mounted. It should be mounted after MountAufs()")
	}

}

func TestContainer_MountAufs(t *testing.T) {
	c := NewContainer(ContainerName)

	if err := c.MountAufs(); err != nil {
		t.Errorf("Could not mount aufs '%s'", err)
	}

	mounted, err := c.CheckMount(c.Path("rootfs"))
	if err != nil {
		t.Error("Could not check mount state of aufs rootfs", err)
	}

	if !mounted {
		t.Error("Aufs rootfs is not mounted. It should be mounted after MountAufs()")
	}

}

func TestContainer_MountPts(t *testing.T) {
	c := NewContainer(ContainerName)

	if err := c.PrepareAndMountPts(); err != nil {
		t.Errorf("Could not mount pts '%s'", err)
	}

	mounted, err := c.CheckMount(c.PtsDir())
	if err != nil {
		t.Error("Could not check mount state of pts dir", err)
	}

	if !mounted {
		t.Error("Pts dir is not mounted. It should be mounted after PrepareAndMountPts()")
	}
}

func TestContainer_AddEbtablesRule(t *testing.T) {
	c := NewContainer(ContainerName)
	c.IP = net.ParseIP("127.0.0.1")

	if err := c.AddEbtablesRule(); err != nil {
		t.Errorf("Could not add ebtables rule '%s'", err)
	}

	available, err := c.CheckEbtables()
	if err != nil {
		t.Error("Could not check ebtables for IP: '%s'", c.IP.String())
	}

	if !available {
		t.Errorf("Ebtables rule for IP '%s' is not available. It should be available after AddEbtablesRule()", c.IP.String())
	}

}

func TestContainer_RemoveEbtablesRule(t *testing.T) {
	c := NewContainer(ContainerName)
	c.IP = net.ParseIP("127.0.0.1")

	if err := c.RemoveEbtablesRule(); err != nil {
		t.Errorf("Could not remove ebtables rule '%s'", err)
	}

	available, err := c.CheckEbtables()
	if err != nil {
		t.Error("Could not check ebtables for IP: '%s'", c.IP.String())
	}

	if available {
		t.Errorf("Ebtables rule for IP '%s' is available. It should be not available after AddEbtablesRule()", c.IP.String())
	}
}

func TestContainer_UmountPts(t *testing.T) {
	c := NewContainer(ContainerName)

	if err := c.UmountPts(); err != nil {
		t.Errorf("Could not mount pts '%s'", err)
	}

	mounted, err := c.CheckMount(c.PtsDir())
	if err != nil {
		t.Error("Could not check mount state of pts dir", err)
	}

	if mounted {
		t.Error("Pts dir is mounted. It should be unmounted after UmountPts()")
	}
}

func TestContainer_UmountAufs(t *testing.T) {
	c := NewContainer(ContainerName)
	if err := c.UmountAufs(); err != nil {
		t.Errorf("Could not umount rbd '%s'", err)
	}

	mounted, err := c.CheckMount(c.Path("rootfs"))
	if err != nil {
		t.Error("Could not check mount state of aufs rootfs", err)
	}

	if mounted {
		t.Error("Aufs rootfs is mounted. It should be unmounted after UmountAufs()")
	}
}

func TestContainer_UmountRBD(t *testing.T) {
	c := NewContainer(ContainerName)
	if err := c.UmountRBD(); err != nil {
		t.Errorf("Could not umount rbd '%s'", err)
	}

	mounted, err := c.CheckMount(c.OverlayPath(""))
	if err != nil {
		t.Error("Could not check mount state of overlay path", err)
	}

	if mounted {
		t.Error("Overlay is mounted. It should be unnmounted after UmountRBD()")
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
