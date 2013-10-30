// +build linux

package container

import (
	"fmt"
	"github.com/caglar10ur/lxc"
	"io"
	"io/ioutil"
	"koding/kites/supervisor/rbd"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"text/template"
	"time"
)

const (
	lxcDir        = "/var/lib/lxc/"
	RootUID       = 0
	UserUIDOffset = 1000000
	RootUIDOffset = 500000
)

var (
	vmRoot      = "/var/lib/lxc/vmroot"
	templateDir = "/opt/koding/go/templates"
	templates   = template.New("container")
)

type Container struct {
	Name string
	Dir  string
	Lxc  *lxc.Container
	UID  int

	// needed for templating
	HwAddr        net.HardwareAddr
	IP            net.IP
	HostnameAlias string
	LdapPassword  string
	sync.Mutex
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

func (c *Container) CopyFile(src, dst string) error {
	sf, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return err
	}

	df, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
	if err != nil {
		return err
	}
	defer df.Close()

	if _, err := io.Copy(df, sf); err != nil {
		return err
	}

	if err := df.Chown(c.UID, c.UID); err != nil {
		return err
	}

	return nil
}

func (c *Container) Chown(name string) error {
	return os.Chown(c.Dir+name, c.UID, c.UID)
}

func (c *Container) PrepareDir(name string) error {
	if err := c.Mkdir(name); err != nil && !os.IsExist(err) {
		return err
	}

	return c.Chown(name)
}

func (c *Container) AsHost() *Container {
	c.UID = RootUID
	return c
}

func (c *Container) AsContainer() *Container {
	c.UID = RootUIDOffset
	return c
}

func (c *Container) PtsDir() string {
	return c.Dir + "rootfs/dev/pts"
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

	if err := file.Chown(c.UID, c.UID); err != nil {
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

func (c *Container) Unprepare(hostnameAlias string) error {
	// first shutdown and stop container
	err := c.Shutdown(3)
	if err != nil {
		return err
	}

	err = c.Stop()
	if err != nil {
		return err
	}

	// backup dpkg database for statistical purposes
	os.Mkdir("/var/lib/lxc/dpkg-statuses", 0755)

	c.AsContainer().CopyFile(c.Dir+"overlay/var/lib/dpkg/status", "/var/lib/lxc/dpkg-statuses/"+c.Name)

	if c.IP == nil {
		if ip, err := ioutil.ReadFile(c.Dir + "ip-address"); err == nil {
			c.IP = net.ParseIP(string(ip))
		}
	}

	if c.IP != nil {
		// remove ebtables entry
		err = c.RemoveEbtablesRule()
		if err != nil {
			return err
		}

		err = c.RemoveStaticRoute()
		if err != nil {
			return err
		}

	}

	err = c.UnmountPts()
	if err != nil {
		return err
	}

	err = c.UnmountAufs()
	if err != nil {
		return err
	}

	err = c.UnmountRBD()
	if err != nil {
		return err
	}

	os.Remove(c.Dir + "overlay")
	os.Remove(c.Dir + "config")
	os.Remove(c.Dir + "fstab")
	os.Remove(c.Dir + "ip-address")
	os.Remove(c.Dir + "rootfs")
	os.Remove(c.Dir + "rootfs.hold")
	os.Remove(c.Dir + "")

	return nil
}

func (c *Container) Prepare(hostnameAlias string) error {
	// vm, err := modelhelper.GetVM(hostnameAlias)
	// if err != nil {
	// 	return err
	// }

	// c.IP = vm.IP
	// c.LdapPassword = vm.LdapPassword

	c.AsHost().PrepareDir("/")
	c.AsHost().GenerateFile("config", "config")
	c.AsHost().GenerateFile("fstab", "fstab")
	c.AsHost().GenerateFile("ip-address", "ip-address")

	err := c.MountRBD()
	if err != nil {
		return err
	}

	c.AsContainer().PrepareDir("/overlay")            // for chown
	c.AsContainer().PrepareDir("/overlay/lost+found") // for chown
	c.AsContainer().PrepareDir("/overlay/etc")

	c.AsContainer().GenerateFile("/overlay/etc/hostname", "hostname")
	c.AsContainer().GenerateFile("/overlay/etc/hosts", "hosts")
	c.AsContainer().GenerateFile("/overlay/etc/ldap.conf", "ldap.conf")

	c.MergePasswdFile()
	c.MergeGroupFile()

	// TODO: merge dpkg database

	err = c.MountAufs()
	if err != nil {
		return err
	}

	err = c.MountPts()
	if err != nil {
		return err
	}

	err = c.AddEbtablesRule()
	if err != nil {
		return err
	}

	err = c.AddStaticRoute()
	if err != nil {
		return err
	}

	return nil
}

func (c *Container) AddStaticRoute() error {
	// add a static route so it is redistributed by BGP
	out, err := exec.Command("/sbin/route", "add", c.IP.String(), "lxcbr0").CombinedOutput()
	if err != nil {
		return fmt.Errorf("adding route failed. err: %s\n out:%s\n", err, out)
	}

	return nil
}

func (c *Container) RemoveStaticRoute() error {
	// remove the static route so it is no longer redistribed by BGP
	out, err := exec.Command("/sbin/route", "del", c.IP.String(), "lxcbr0").CombinedOutput()
	if err != nil {
		return fmt.Errorf("removing route failed. err: %s\n out:%s\n", err, out)
	}

	return nil
}

func (c *Container) AddEbtablesRule() error {
	// add ebtables entry to restrict IP and MAC
	out, err := exec.Command("/sbin/ebtables", "--append", "VMS", "--protocol", "IPv4", "--source",
		c.MAC().String(), "--ip-src", c.IP.String(), "--in-interface", c.VEth(),
		"--jump", "ACCEPT").CombinedOutput()
	if err != nil {
		return fmt.Errorf("ebtables rule addition failed. err: %s\n out:%s\n", err, out)
	}

	return nil
}

func (c *Container) RemoveEbtablesRule() error {
	// add ebtables entry to restrict IP and MAC
	out, err := exec.Command("/sbin/ebtables", "--delete", "VMS", "--protocol", "IPv4", "--source",
		c.MAC().String(), "--ip-src", c.IP.String(), "--in-interface", c.VEth(),
		"--jump", "ACCEPT").CombinedOutput()
	if err != nil {
		return fmt.Errorf("ebtables rule deletion failed.", err, out)
	}

	return nil
}

func (c *Container) MountAufs() error {
	c.AsContainer().PrepareDir("rootfs")

	// if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "overlayfs", "-o", fmt.Sprintf("lowerdir=%s,upperdir=%s", vm.LowerdirFile("/"), vm.OverlayFile("/")), "overlayfs", vm.File("rootfs")).CombinedOutput(); err != nil {

	// mount "/var/lib/lxc/vm-{id}/overlay" (rw) and "/var/lib/lxc/vmroot" (ro)
	// under "/var/lib/lxc/vm-{id}/rootfs"
	out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "aufs", "-o",
		fmt.Sprintf("noplink,br=%s:%s", c.Dir+"/overlay", vmRoot+"/rootfs/"),
		"aufs", c.Dir+"rootfs").CombinedOutput()
	if err != nil {
		return fmt.Errorf("mount overlay failed. err: %s\n out:%s\n", err, out)
	}

	return nil
}

func (c *Container) UnmountAufs() error {
	out, err := exec.Command("/sbin/auplink", c.Dir+"rootfs", "flush").CombinedOutput()
	if err != nil {
		return fmt.Errorf("AUFS flush failed.", err, out)
	}

	out, err = exec.Command("/bin/umount", c.Dir+"rootfs").CombinedOutput()
	if err != nil {
		return fmt.Errorf("umount overlay failed.", err, out)
	}

	return nil
}

func (c *Container) MountPts() error {
	c.AsContainer().PrepareDir(c.PtsDir())

	out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "devpts", "-o",
		"rw,noexec,nosuid,newinstance,gid="+strconv.Itoa(RootUIDOffset+5)+",mode=0620,ptmxmode=0666",
		"devpts", c.PtsDir()).CombinedOutput()
	if err != nil {
		return fmt.Errorf("mount devpts failed. err: %s\n out:%s\n", err, out)
	}

	c.AsContainer().Chown(c.PtsDir())
	c.AsContainer().Chown(c.PtsDir() + "/ptmx")

	return nil
}

func (c *Container) UnmountPts() error {
	out, err := exec.Command("/bin/umount", c.PtsDir()).CombinedOutput()
	if err != nil {
		return fmt.Errorf("umount devpts failed.", err, out)
	}

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

	// protect fsck.ext4 is not concurrent ready
	c.Lock()
	defer c.Unlock()

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

func (c *Container) UnmountRBD() error {
	r := rbd.NewRBD(c.Name)

	out, err := exec.Command("/bin/umount", c.Dir+"/overlay").CombinedOutput()
	if err != nil {
		return fmt.Errorf("umount rbd failed.", err, out)
	}

	out, err = r.Unmap()
	if err != nil {
		return fmt.Errorf("rbd unmap failed.", err, out)
	}

	return nil

}
