// +build linux

package container

import (
	"fmt"
	"github.com/caglar10ur/lxc"
	"koding/kites/supervisor/rbd"
	"net"
	"os"
	"os/exec"
	"strings"
	"syscall"
	"text/template"
	"time"
)

const (
	lxcDir  = "/var/lib/lxc/"
	rootUID = 0
)

var (
	templateDir = "/opt/koding/go/templates"
	templates   = template.New("container")
)

type Container struct {
	Name          string
	Dir           string
	Lxc           *lxc.Container
	HwAddr        net.HardwareAddr
	IP            net.IP
	HostnameAlias string
}

func init() {
	interf, err := net.InterfaceByName("lxcbr0")
	if err != nil {
		panic(err)
	}

	addrs, err := interf.Addrs()
	if err != nil {
		panic(err)
	}

	hostIP, _, err := net.ParseCIDR(addrs[0].String())
	if err != nil {
		panic(err)
	}

	templates.Funcs(template.FuncMap{
		"hostIP": func() string {
			return hostIP.String()
		},
		"swapAccountingEnabled": func() bool {
			_, err := os.Stat("/sys/fs/cgroup/memory/memory.memsw.limit_in_bytes")
			return err == nil
		},
		"kernelMemoryAccountingEnabled": func() bool {
			_, err := os.Stat("/sys/fs/cgroup/memory/memory.kmem.limit_in_bytes")
			return err == nil
		},
	})

	if _, err := templates.ParseGlob(templateDir + "/vm/*"); err != nil {
		panic(err)
	}

}

func NewContainer(containerName string) *Container {
	return &Container{
		Name: containerName,
		Dir:  lxcDir + containerName + "/",
		Lxc:  lxc.NewContainer(containerName),
	}
}

func (c *Container) String() string {
	return c.Name
}

// Generate unique MAC address from IP address
func (c *Container) MAC() net.HardwareAddr {
	return net.HardwareAddr([]byte{0, 0, c.IP[12], c.IP[13], c.IP[14], c.IP[15]})
}

// Generate unique VEth pair from IP address
func (c *Container) VEth() string {
	return fmt.Sprintf("veth-%x", []byte(c.IP[12:16]))
}

func (c *Container) Mkdir(name string) error {
	return os.Mkdir(c.Dir+name, 0755)
}

func (c *Container) GenerateFile(name, template string) error {
	var mode os.FileMode = 0644

	file, err := os.OpenFile(c.Dir+name, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	defer file.Close()

	if err := templates.ExecuteTemplate(file, template, c); err != nil {
		return err
	}

	if err := file.Chown(rootUID, rootUID); err != nil {
		return err
	}

	if err := file.Chmod(mode); err != nil {
		return err
	}

	return nil

}

func (c *Container) IsRunning() bool {
	return c.Lxc.Running()
}

func (c *Container) Create(template string) error {
	return c.Lxc.Create(template)
}

func (c *Container) Run(command string) error {
	args := strings.Split(strings.TrimSpace(command), " ")

	if err := c.Lxc.AttachRunCommand(args...); err != nil {
		return fmt.Errorf("ERROR: %s\n", err.Error())
	}

	return nil
}

func (c *Container) Start() error {
	err := c.Lxc.SetDaemonize()
	if err != nil {
		return fmt.Errorf("ERROR: %s\n", err)
	}

	err = c.Lxc.Start(false)
	if err != nil {
		return fmt.Errorf("ERROR: %s\n", err)
	}

	return nil
}

func (c *Container) Stop() error {
	err := c.Lxc.Stop()
	if err != nil {
		return fmt.Errorf("ERROR: %s\n", err)
	}

	return nil
}

func (c *Container) Shutdown(timeout int) error {
	err := c.Lxc.Shutdown(timeout)
	if err != nil {
		return fmt.Errorf("ERROR: %s\n", err)
	}

	return nil
}

func (c *Container) Destroy() error {
	return c.Lxc.Destroy()
}

func (c *Container) Prepare(hostnameAlias string) error {
	// vm, err := modelhelper.GetVM(hostnameAlias)
	// if err != nil {
	// 	return err
	// }

	// c.IP = vm.IP

	c.Mkdir("/")
	c.GenerateFile("config", "config")
	c.GenerateFile("fstab", "fstab")
	c.GenerateFile("ip-address", "ip-address")

	err := c.MountRBD()
	if err != nil {
		return err
	}

	// * create overlay directory (/var/lib/lxc/vm-{id}/overlay) with following content:
	// 	"/"
	// 	"/lost+found"
	// 	"/etc"
	// 	"/etc/hostname"
	// 	"/etc/hosts"
	// 	"/etc/ldap.conf"
	// * create rootfs directory (/var/lob/lxc/vm-{id}/vmroot)
	// * mount aufs. "/var/lib/lxc/vm-{id}/overlay" (rw) and "/var/lib/lxc/vmroot" (ro)
	// under "/var/lib/lxc/vm-{id}/rootfs". overlay on top of vmroot and define this
	// to the folder 'rootfs'.
	// * create ptsdir and mount it
	// * add ebtables entry to restrict IP and MAC
	// * add a static route so it is redistributed by BGP

	return nil
}

func (c *Container) MountRBD() error {
	r := rbd.NewRBD(c.Name)
	out, err := r.Info(c.Name)
	if err != nil {
		return err
	}

	makeFileSystem := false
	// means image doesn't exist, create new one
	if out == nil {
		if _, err := r.Create(c.Name, "1024"); err != nil {
			return err
		}

		makeFileSystem = true
	}

	_, err = r.Map(c.Name)
	if err != nil {
		return err
	}

	// wait for rbd device to appear
	for {
		_, err := os.Stat(r.Device)
		if err == nil {
			break
		}
		if !os.IsNotExist(err) {
			return err
		}
		time.Sleep(time.Second / 2)
	}

	if makeFileSystem {
		if out, err := exec.Command("/sbin/mkfs.ext4", r.Device).CombinedOutput(); err != nil {
			return fmt.Errorf("mkfs.ext4 failed.", err, out)
		}
	}

	mountDir := c.Dir + "overlay"

	// check/correct filesystem
	if out, err := exec.Command("/sbin/fsck.ext4", "-p", r.Device).CombinedOutput(); err != nil {
		exitError, ok := err.(*exec.ExitError)
		if !ok || exitError.Sys().(syscall.WaitStatus).ExitStatus() == 4 {
			if out, err := exec.Command("/sbin/fsck.ext4", "-y", r.Device).CombinedOutput(); err != nil {
				exitError, ok := err.(*exec.ExitError)
				if !ok || exitError.Sys().(syscall.WaitStatus).ExitStatus() != 1 {
					return fmt.Errorf(fmt.Sprintf("fsck.ext4 could not automatically repair FS for %s.", c.HostnameAlias), err, out)
				}
			}
		} else {
			return fmt.Errorf(fmt.Sprintf("fsck.ext4 failed %s.", c.HostnameAlias), err, out)
		}
	}

	if err := os.Mkdir(mountDir, 0755); err != nil && !os.IsExist(err) {
		return err
	}

	if out, err := exec.Command("/bin/mount", "-t", "ext4", r.Device, mountDir).CombinedOutput(); err != nil {
		os.Remove(mountDir)
		return fmt.Errorf("mount rbd failed.", err, out)
	}

	return nil
}
