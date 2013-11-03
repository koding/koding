package container

import (
	"fmt"
	"io/ioutil"
	"koding/kites/supervisor/rbd"
	"net"
	"os"
	"os/exec"
	"regexp"
)

// Unprepare is basically the inverse of Prepare. We don't use lxc.destroy
// (which purges the container immediately). Instead we use this method which
// basically let us umount previously mounted disks, remove generated files,
// etc. It doesn't remove the home folder or any newly created system files.
// Those files will be stored in the vmroot.
func (c *Container) Unprepare() error {
	err := c.CheckAndStopContainer()
	if err != nil {
		return nil
	}

	err = c.BackupDpkg()
	if err != nil {
		return err
	}

	err = c.RemoveNetworkRules()
	if err != nil {
		return err
	}

	err = c.UmountPts()
	if err != nil {
		return err
	}

	err = c.UmountAufs()
	if err != nil {
		return err
	}

	err = c.UmountRBD()
	if err != nil {
		return err
	}

	err = c.RemoveContainerFiles()
	if err != nil {
		return err
	}

	return nil
}

func (c *Container) CheckAndStopContainer() error {
	if !c.IsRunning() {
		return nil
	}

	fmt.Println("stopping down containers")
	err := c.Stop()
	if err != nil {
		return err
	}

	return nil
}

func (c *Container) BackupDpkg() error {
	// backup dpkg database for statistical purposes
	os.Mkdir("/var/lib/lxc/dpkg-statuses", 0755)
	c.AsContainer().CopyFile(c.OverlayPath("/var/lib/dpkg/status"),
		"/var/lib/lxc/dpkg-statuses/"+c.Name)

	return nil // silently fail, because a newly prepared vm doesn't have this file
}

func (c *Container) RemoveNetworkRules() error {
	if c.IP == nil {
		if ip, err := ioutil.ReadFile(c.Path("ip-address")); err == nil {
			c.IP = net.ParseIP(string(ip))
		}
	}

	if c.IP != nil {
		// remove ebtables entry
		err := c.RemoveStaticRoute()
		if err != nil {
			return err
		}

		err = c.RemoveEbtablesRule()
		if err != nil {
			return err
		}
	}

	return nil
}

func (c *Container) RemoveContainerFiles() error {
	// our overlay folder
	err := os.Remove(c.OverlayPath(""))
	if err != nil {
		return err
	}

	// container files
	os.Remove(c.Path("config"))
	os.Remove(c.Path("fstab"))
	os.Remove(c.Path("ip-address"))

	// remove
	err = os.Remove(c.Path("rootfs"))
	if err != nil {
		return err
	}

	os.Remove(c.Path("rootfs.hold"))

	// finally remove our container dir
	err = os.Remove(c.Path(""))
	if err != nil {
		return err
	}

	return nil
}

func (c *Container) RemoveEbtablesRule() error {
	isAvailable, err := c.CheckEbtables()
	if err != nil {
		return err
	}

	if !isAvailable {
		return nil
	}

	// add ebtables entry to restrict IP and MAC
	out, err := exec.Command("/sbin/ebtables", "--delete", "VMS", "--protocol", "IPv4", "--source",
		c.MAC().String(), "--ip-src", c.IP.String(), "--in-interface", c.VEth(),
		"--jump", "ACCEPT").CombinedOutput()
	if err != nil {
		return fmt.Errorf("ebtables rule deletion failed. err: %s\n out:%s\n", err, string(out))
	}

	return nil
}

func (c *Container) CheckEbtables() (bool, error) {
	cmd := exec.Command("/sbin/ebtables", "--list")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return false, err
	}

	return regexp.Match(c.IP.String(), out)
}

func (c *Container) RemoveStaticRoute() error {
	// remove the static route so it is no longer redistribed by BGP
	out, err := exec.Command("/sbin/route", "del", c.IP.String(), "lxcbr0").CombinedOutput()
	if err != nil {
		return fmt.Errorf("removing route failed. err: %s\n out:%s\n", err, out)
	}

	return nil
}

func (c *Container) UmountPts() error {
	out, err := exec.Command("/bin/umount", c.PtsDir()).CombinedOutput()
	if err != nil {
		return fmt.Errorf("umount devpts failed. err: %s\n out:%s\n", err, string(out))
	}

	return nil
}

func (c *Container) UmountAufs() error {
	out, err := exec.Command("/sbin/auplink", c.Path("rootfs"), "flush").CombinedOutput()
	if err != nil {
		return fmt.Errorf("aufs flush failed. err: %s\n out:%s\n", err, string(out))
	}

	out, err = exec.Command("/bin/umount", c.Path("rootfs")).CombinedOutput()
	if err != nil {
		return fmt.Errorf("umount rootfs failed. err: %s\n out:%s\n", err, string(out))
	}

	return nil
}

func (c *Container) UmountRBD() error {
	out, err := exec.Command("/bin/umount", c.OverlayPath("")).CombinedOutput()
	if err != nil {
		return fmt.Errorf("umount overlay failed. err: %s\n out:%s\n", err, string(out))
	}

	r := rbd.NewRBD(c.Name)
	out, err = r.Unmap()
	if err != nil {
		return fmt.Errorf("rbd unmap failed. err: %s\n out:%s\n", err, string(out))
	}

	return nil

}
