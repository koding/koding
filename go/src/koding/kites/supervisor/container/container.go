// +build linux

package container

import (
	"fmt"
	"github.com/caglar10ur/lxc"
	"os"
	"strings"
)

const lxcDir = "/var/lib/lxc/"
const rootUID = 0

type Container struct {
	Name string
	Dir  string
	Lxc  *lxc.Container
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

func (c *Container) Mkdir(name string) error {
	return os.Mkdir(c.Dir+name, 0755)
}

func (c *Container) GenerateFile(name, template string, data interface{}) error {
	var mode os.FileMode = 0644

	file, err := os.OpenFile(name, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	defer file.Close()

	// if err := Templates.ExecuteTemplate(file, template, data); err != nil {
	// 	return err
	// }

	if err := file.Chown(rootUID, rootUID); err != nil {
		return err
	}

	if err := file.Chmod(mode); err != nil {
		return err
	}

	return nil

}

func (c *Container) Run(command string) error {
	fmt.Printf("running '%s' on '%s'\n", command, c.Name)
	args := strings.Split(strings.TrimSpace(command), " ")

	if err := c.Lxc.AttachRunCommand(args...); err != nil {
		return fmt.Errorf("ERROR: %s\n", err.Error())
	}

	return nil
}

func (c *Container) Start() error {
	fmt.Println("starting ", c.Name)
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
	fmt.Println("stopping ", c.Name)
	err := c.Lxc.Stop()
	if err != nil {
		return fmt.Errorf("ERROR: %s\n", err)
	}

	return nil
}

func (c *Container) Shutdown(timeout int) error {
	fmt.Println("shutting down ", c.Name)
	err := c.Lxc.Shutdown(timeout)
	if err != nil {
		return fmt.Errorf("ERROR: %s\n", err)
	}

	return nil
}

func (c *Container) Create(template string) error {
	fmt.Printf("creating vm '%s' with template '%s'\n", c.Name, template)
	return c.Lxc.Create(template)
}

func (c *Container) Destroy() error {
	fmt.Println("destroying ", c.Name)
	return c.Lxc.Destroy()
}

func (c *Container) Prepare(hostnameAlias string) error {
	fmt.Printf("preparing container '%s'\n", c.Name)

	c.Mkdir("/")
	c.GenerateFile("/config", "config", nil)
	c.GenerateFile("/fstab", "fstab", nil)
	c.GenerateFile("/ip-address", "ip-address", nil)

	// * create Vm struct or get one and modify it
	// * get vmroot directory (/var/lib/lxc/vmroot)
	// * create lxc directory (/var/lib/lxc/vm-{id}) with following files: config, fstab, ip-address
	// * map rbd image to block device ?
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
