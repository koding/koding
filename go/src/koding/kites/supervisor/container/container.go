// +build linux

package container

import (
	"fmt"
	"github.com/caglar10ur/lxc"
	"io"
	"net"
	"os"
	"strings"
	"sync"
	"text/template"
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
	Username      string
	Useruid       int
	WebHome       string

	sync.Mutex // protects mount commands
}

// It's put here that it get initiated only once
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

	fmt.Printf("copying from '%s' to '%s'", sf.Name(), df.Name())
	if _, err := io.Copy(df, sf); err != nil {
		return err
	}

	if err := df.Chown(c.UID, c.UID); err != nil {
		return err
	}

	return nil
}

func (c *Container) Chown(name string) error {
	fmt.Println("chowning ", name, c.UID)
	return os.Chown(name, c.UID, c.UID)
}

func (c *Container) Lchown(name string) error {
	return os.Lchown(name, c.UID, c.UID)
}

func (c *Container) PrepareDir(name string) error {
	if err := os.Mkdir(name, 0755); err != nil && !os.IsExist(err) {
		return err
	}

	return c.Chown(name)
}

func (c *Container) Path(file string) string {
	return c.Dir + file
}

func (c *Container) OverlayPath(file string) string {
	return c.Dir + "overlay/" + file
}

func (c *Container) AsHost() *Container {
	c.UID = RootUID
	return c
}

func (c *Container) AsContainer() *Container {
	c.UID = RootUIDOffset
	return c
}

func (c *Container) AsUser() *Container {
	c.UID = c.Useruid
	return c
}

func (c *Container) PtsDir() string {
	return c.Dir + "rootfs/dev/pts"
}

func (c *Container) GenerateFile(name, template string) error {
	var mode os.FileMode = 0644

	file, err := os.OpenFile(name, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode)
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
