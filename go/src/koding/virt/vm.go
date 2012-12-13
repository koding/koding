package virt

import (
	"fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"os/user"
	"strconv"
	"text/template"
)

type VM struct {
	ID   int    "_id"
	Name string "name"
}

const VMROOT_ID = 1000000

var templates *template.Template
var vmDB *mgo.Collection

func init() {
	var err error
	templates, err = template.ParseGlob("templates/lxc/*")
	if err != nil {
		panic(err)
	}

	session, err := mgo.Dial("dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2")
	if err != nil {
		panic(err)
	}
	vmDB = session.DB("koding_dev2").C("jVMs")
}

func Find(query interface{}) (*VM, error) {
	var vm VM
	err := vmDB.Find(query).One(&vm)
	if err != nil {
		return nil, err
	}
	return &vm, nil
}

func FindById(id int) (*VM, error) {
	return Find(bson.M{"_id": id})
}

func FindByIP(a, b, c, d byte) (*VM, error) {
	if a != 10 || b == 0 {
		return nil, fmt.Errorf("Illegal VM address: %d.%d.%d.%d", a, b, c, d)
	}
	return FindById(int(b)<<16 + int(c)<<8 + int(d)<<0)
}

func FindByUid(uid int) (*VM, error) {
	return FindById(uid >> 8)
}

func FindByName(name string) (*VM, error) {
	return Find(bson.M{"name": name})
}

func (vm *VM) String() string {
	return vm.IP().String()
}

func (vm *VM) IP() net.IP {
	return net.IPv4(10, byte(vm.ID>>16), byte(vm.ID>>8), byte(vm.ID>>0))
}

func (vm *VM) MAC() net.HardwareAddr {
	return net.HardwareAddr([]byte{0, 0, 10, byte(vm.ID >> 16), byte(vm.ID >> 8), byte(vm.ID >> 0)})
}

func (vm *VM) Uid() int {
	return vm.ID << 8
}

func (vm *VM) Username() string {
	u, err := user.LookupId(strconv.Itoa(vm.Uid()))
	if err != nil {
		return "nobody"
	}
	return u.Username
}

func (vm *VM) Hostname() string {
	return "koding-" + vm.Username()
}

func (vm *VM) File(path string) string {
	return fmt.Sprintf("/var/lib/lxc/%s/%s", vm, path)
}

func (vm *VM) UpperdirFile(path string) string {
	return vm.File("overlayfs-upperdir/" + path)
}

func LowerdirFile(path string) string {
	return "/var/lib/lxc/vmroot/rootfs/" + path
}

func (vm *VM) Prepare() {
	// create directories
	vm.Mkdir("", false)
	vm.Mkdir("overlayfs-upperdir", true)
	vm.Mkdir("overlayfs-upperdir/etc", true)
	vm.Mkdir("overlayfs-upperdir/home/"+vm.Username(), true)
	vm.Mkdir("rootfs", true)

	// write LXC files
	vm.GenerateFile("config", false)
	vm.GenerateFile("pre-start", true)
	vm.GenerateFile("post-stop", true)
	vm.GenerateFile("fstab", false)

	// write hostname file
	hostnameFile := vm.UpperdirFile("/etc/hostname")
	hostname, err := os.Create(hostnameFile)
	if err != nil {
		panic(err)
	}
	hostname.Write([]byte(vm.Username() + ".koding.com\n"))
	hostname.Close()
	os.Chown(hostnameFile, VMROOT_ID, VMROOT_ID)

	vm.MergePasswdFile()
	vm.MergeGroupFile()
	vm.MergeDpkgDatabase()
}

func (vm *VM) Mkdir(path string, chown bool) {
	fullPath := fmt.Sprintf("/var/lib/lxc/%s/%s", vm, path)
	os.Mkdir(fullPath, 0755)
	if chown {
		os.Chown(fullPath, VMROOT_ID, VMROOT_ID)
	}
}

func (vm *VM) GenerateFile(name string, executable bool) {
	file, err := os.Create(vm.File(name))
	if err != nil {
		panic(err)
	}
	defer file.Close()

	err = templates.ExecuteTemplate(file, name, vm)
	if err != nil {
		panic(err)
	}

	if executable {
		file.Chmod(0755)
	} else {
		file.Chmod(0644)
	}
}
