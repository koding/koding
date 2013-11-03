package container

import (
	"fmt"
	"net"
	"os"
	"testing"
)

const (
	ContainerName = "tt"
	ContainerIP   = "10.0.1.33" // TODO: take subnet from config
)

var c = NewContainer(ContainerName)

func init() {
	c.HostnameAlias = "vagrant"
	c.LdapPassword = "123456789"
	c.IP = net.ParseIP(ContainerIP)
	c.Username = "testing"
	c.WebHome = "testing"
}

func exist(filename string) bool {
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		return false
	}

	return true
}

func TestNewContainer(t *testing.T) {
	if c.Name != ContainerName {
		t.Errorf("NewContainer: exptecting: %s got: %s", ContainerName, c.Name)
	}

	containerDir := lxcDir + ContainerName + "/"

	if c.Path("") != containerDir {
		t.Errorf("NewContainer: exptecting: %s got: %s", containerDir, c.Dir)
	}

}

func TestContainer_CreateContainerDir_prepare(t *testing.T) {
	var files = []struct {
		fileName string
		template string
	}{
		{c.Path("config"), "config"},
		{c.Path("fstab"), "fstab"},
		{c.Path("ip-address"), "ip-address"},
	}

	err := c.CreateContainerDir()
	if err != nil {
		t.Errorf("Could not create container dir: '%s'", err)
	}

	for _, file := range files {
		if !exist(file.fileName) {
			t.Errorf("Generatefile: %s does not exist", file.fileName)
		}
	}
}

func TestContainer_MountRBD_prepare(t *testing.T) {
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

func TestContainer_CreateOverlay_prepare(t *testing.T) {
	var containerFiles = []struct {
		fileName string
		template string
	}{
		{c.OverlayPath("etc/hostname"), "hostname"},
		{c.OverlayPath("etc/hosts"), "hosts"},
		{c.OverlayPath("etc/ldap.conf"), "ldap.conf"},
	}

	err := c.CreateOverlay()
	if err != nil {
		t.Errorf("Could not create overlay files: '%s'", err)
	}

	for _, file := range containerFiles {
		if !exist(file.fileName) {
			t.Errorf("Generatefile: %s does not exist", file.fileName)
		}
	}
}

func TestContainer_MountAufs_prepare(t *testing.T) {
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

func TestContainer_MountPts_prepare(t *testing.T) {
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

func TestContainer_AddEbtablesRule_prepare(t *testing.T) {
	c.IP = net.ParseIP(ContainerIP)

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

func TestContainer_AddStaticRoute_prepare(t *testing.T) {
	if err := c.AddStaticRoute(); err != nil {
		t.Errorf("Could not add static route rule '%s'", err)
	}

	available, err := c.CheckStaticRoute()
	if err != nil {
		t.Error("Could not check static route for IP: '%s'", c.IP.String())
	}

	if !available {
		t.Errorf("Static route for IP '%s' is not available. It should be available after AddStaticRoute()", c.IP.String())
	}
}

func TestContainer_PrepareHomeDirectory_prepare(t *testing.T) {
	err := c.PrepareHomeDirectory()
	if err != nil {
		t.Errorf("Could not create home directory: '%s'", err)

	}

	if !exist(c.Path("rootfs/home/testing")) {
		t.Error("User home directory does not exist")
	}

	vmWebDir := c.Path(fmt.Sprintf("rootfs/home/%s/Web", c.WebHome))
	if !exist(vmWebDir) {
		t.Error("User web directory does not exist")
	}

}

func TestContainer_CheckAndStopContainer_unprepare(t *testing.T) {
	err := c.CheckAndStopContainer()
	if err != nil {
		t.Errorf("Could not stop the container: '%s'", err)
	}

	if c.IsRunning() {
		t.Error("Container is still running (it should be stopped)")
	}
}

func TestContainer_BackupDpkg_unprepare(t *testing.T) {
	err := c.BackupDpkg()
	if err != nil {
		t.Errorf("Could not backup dpkg files: '%s'", err)
	}
}

func TestContainer_RemoveStaticRoute_unprepare(t *testing.T) {
	if err := c.RemoveStaticRoute(); err != nil {
		t.Errorf("Could not remove static route rule '%s'", err)
	}

	available, err := c.CheckStaticRoute()
	if err != nil {
		t.Error("Could not check static route for IP: '%s'", c.IP.String())
	}

	if available {
		t.Errorf("Static route for IP '%s' is available. It should be not available after RemoveStaticRoute()", c.IP.String())
	}
}

func TestContainer_RemoveEbtablesRule_unprepare(t *testing.T) {
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

func TestContainer_UmountPts_unprepare(t *testing.T) {
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

func TestContainer_UmountAufs_unprepare(t *testing.T) {
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

func TestContainer_UmountRBD_unprepare(t *testing.T) {
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

func TestContainer_RemoveContainerFiles_unprepare(t *testing.T) {
	files := []string{
		c.OverlayPath(""),
		c.Path("config"),
		c.Path("fstab"),
		c.Path("ip-addres"),
		c.Path("rootfs"),
		c.Path("rootfs.hold"),
		c.Path(""),
	}

	err := c.RemoveContainerFiles()
	if err != nil {
		t.Errorf("Could not remove container dir and files: '%s'", err)
	}

	for _, file := range files {
		if exist(file) {
			t.Errorf("Removing container files: %s does exist", file)
		}
	}
}
