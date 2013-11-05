// +build linux

package container

import (
	"bytes"
	"errors"
	"fmt"
	"github.com/caglar10ur/lxc"
	"io"
	"net"
	"os"
	"os/exec"
	"strconv"
	"sync"
	"text/template"
)

const (
	lxcDir        = "/var/lib/lxc/"
	lxcVersion    = "1.0.0.alpha1"
	RootUID       = 0       // id of the root user
	UserUIDOffset = 1000000 // used for id mapping in lxc.conf
	RootUIDOffset = 500000  // used for id mapping in lxc.conf
)

var (
	// contains the rootfs that is used for templating our lxc's. the vmroot
	// is created manually via a script. It can be found in sysops  git repo
	// under: lxc-vmroot-generator/prepareVMRoot.sh
	vmRoot = "/var/lib/lxc/vmroot"

	// used for bootrapping lxc container. It contains the templates for
	// creating files like config, fstab. It also contains folders that is used
	// to create the home and web directory for new containers.
	templateDir = "/opt/koding/go/templates"
	templates   = template.New("container")
)

type Container struct {
	Name string // ContainerName
	Dir  string // Container directory path, i.e: /var/lib/lxc/containerName/
	UID  int    // Used for AsXXX() methods.

	// needed for templating and preparing a single Container
	HwAddr        net.HardwareAddr
	IP            net.IP
	HostnameAlias string
	LdapPassword  string
	Username      string
	Useruid       int
	WebHome       string
	DiskSizeInMB  int

	sync.Mutex // protects linux commands such as 'mount' or 'fsck'
}

func init() {
	if lxc.Version() != lxcVersion {
		fmt.Printf("lxc version mismatch. expected: '%s' got: '%s'\n", lxcVersion, lxc.Version())
		os.Exit(1)
	}

	if os.Geteuid() != 0 {
		fmt.Println("running as non-root")
		os.Exit(1)
	}

	// it's put here that it get initiated only once
	loadTemplates()
}

// NewContainer returns a new instance of the Container struct.
func NewContainer(containerName string) *Container {
	return &Container{
		Name: containerName,
		Dir:  lxcDir + containerName + "/",
	}
}

// String representation of the container. Returns the containername that is
// passed to lxc's --name option.
func (c *Container) String() string {
	return c.Name
}

// Generate unique MAC address from IP address.
func (c *Container) MAC() net.HardwareAddr {
	return net.HardwareAddr([]byte{0, 0, c.IP[12], c.IP[13], c.IP[14], c.IP[15]})
}

// Generate unique VEth pair from IP address
func (c *Container) VEth() string {
	return fmt.Sprintf("veth-%x", []byte(c.IP[12:16]))
}

// Path returns the absolute path of a file that residue in the container. For
// example c.Path("config") will return: "/var/lib/lxc/containerName/config".
func (c *Container) Path(file string) string {
	return c.Dir + file
}

// Overlaypath returns the absolute path of a file that residue in the
// containers overlay folder. For example c.OverlayPath("/etc/hosts") will return:
// "/var/lib/lxc/containerName/overlaay/etc/hosts".
func (c *Container) OverlayPath(file string) string {
	return c.Dir + "overlay/" + file
}

// AsHost returns a new instance of Container with the UID and GID set to the
// host's root user. It is used to be chained with methods like Chown or
// Lchown.
func (c *Container) AsHost() *Container {
	c.UID = RootUID
	return c
}

// AsContainer returns a new instance of Container with the UID and GID set to
// the containers's root user. It is used to be chained with methods like
// Chown or Lchown.
func (c *Container) AsContainer() *Container {
	c.UID = RootUIDOffset
	return c
}

// AsUser returns a new instance of Container with the UID and GID set to the
// containers's default user. It is used to be chained with methods like Chown
// or Lchown.
func (c *Container) AsUser() *Container {
	c.UID = c.Useruid
	return c
}

// CopyFile copyies the src path to the dst path, the paths should be absoule.
// It should be chained with an AsXXX() function because it also calles chown
// on the newly dst file. An example call might be:
// c.AsUser().CopyFile("/Users/arslan/example.txt", c.OverlayPath("/home/arslan/example.txt"))
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

// Chown is a wrapper around os.Chown. It's need to be chained with AsXXX()
// method which sets the UID and GUID. An example call might be:
// c.AsContainer().Chown("example.txt")
func (c *Container) Chown(name string) error {
	return os.Chown(name, c.UID, c.UID)
}

// Lchown is a wrapper around os.Lchown. It's need to be chained with a AsXXX()
// method which sets the UID and GUID. An example call might be:
// c.AsContainer().Lchown("example.txt")
func (c *Container) Lchown(name string) error {
	return os.Lchown(name, c.UID, c.UID)
}

// Exist returns if the given path exist
func (c *Container) Exist(filename string) bool {
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		return false
	}

	return true
}

// PrepareDir creates a new directory with and chowns it. It's need to be
// chained with a AsXXX() method.
func (c *Container) PrepareDir(name string) error {
	if err := os.Mkdir(name, 0755); err != nil && !os.IsExist(err) {
		return err
	}

	return c.Chown(name)
}

// PtsDir return the container's pts path.
func (c *Container) PtsDir() string {
	return c.Dir + "rootfs/dev/pts"
}

// Generatefile generates a new file based on the template in the templateDir.
// Name should is the path the file is going to be stored.
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

// IsRunning returns true if the container is running.
func (c *Container) IsRunning() bool {
	l := lxc.NewContainer(c.Name)
	defer lxc.PutContainer(l)

	return l.Running()
}

// Create creates a new lxc based on the template.
func (c *Container) Create(template string) error {
	l := lxc.NewContainer(c.Name)
	defer lxc.PutContainer(l)

	if !l.Create(template, []string{}) {
		return fmt.Errorf("could not create: %s\n", c.Name)
	}
	return nil

}

// Run invokes the given command inside the container.
func (c *Container) Run(command string) ([]byte, error) {
	if !c.IsRunning() {
		return nil, errors.New("vm is not running")
	}

	args := []string{"--name", c.Name, "--", "/usr/bin/sudo", "-i", "-u",
		"#" + strconv.Itoa(c.Useruid), "--", "/bin/bash", "-c", command}

	cmd := exec.Command("/usr/bin/lxc-attach", args...)
	cmd.Env = []string{"TERM=xterm-256color"}
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, err
	}

	return bytes.TrimSpace(out), nil
}

// Start starts the container. It calls lxc-start with --daemonize set to
// true. Current binding
func (c *Container) Start() error {
	if !c.Exist(c.Dir) {
		return errors.New("container does not exist. please prepare it")
	}

	out, err := exec.Command("/usr/bin/lxc-start", "--name", c.Name, "--daemon").CombinedOutput()
	if err != nil {
		fmt.Println("lxc-start failed", err, string(out))
		return fmt.Errorf("could not start '%s'", c.Name)
	}

	return nil
}

// Stop stops the running container. It calls lxc-stop.
func (c *Container) Stop() error {
	if !c.Exist(c.Dir) {
		return errors.New("container does not exist. please prepare it")
	}

	l := lxc.NewContainer(c.Name)
	defer lxc.PutContainer(l)

	if !l.Stop() {
		return fmt.Errorf("could not stop: %s\n", c.Name)
	}

	return nil
}

// Shutdown stops the running container after the given timeout. It calls lxc-stop.
func (c *Container) Shutdown(timeout int) error {
	l := lxc.NewContainer(c.Name)
	defer lxc.PutContainer(l)

	if !l.Shutdown(timeout) {
		return fmt.Errorf("could not shutdown: %s\n", c.Name)
	}

	return nil
}

// Destroy detroys the given container. It calls lxc-destroy.
func (c *Container) Destroy() error {
	l := lxc.NewContainer(c.Name)
	defer lxc.PutContainer(l)

	if !l.Destroy() {
		return fmt.Errorf("could not destroy: %s\n", c.Name)
	}

	return nil
}

func loadTemplates() {
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
