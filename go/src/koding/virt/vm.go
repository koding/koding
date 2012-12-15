package virt

import (
	"fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"os/exec"
	"text/template"
	"time"
)

type VM struct {
	Id   int    "_id"
	Name string "name"
	Used bool   "used"
}

type Counter struct {
	Value int "v"
}

const VMROOT_ID = 1000000

var templates *template.Template
var VMs *mgo.Collection
var Counters *mgo.Collection

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
	db := session.DB("koding_dev2")
	VMs = db.C("jVMs")
	Counters = db.C("jCounters")
}

func Find(query interface{}) (*VM, error) {
	var vm VM
	err := VMs.Find(query).One(&vm)
	return &vm, err
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
	return net.IPv4(10, byte(vm.Id>>16), byte(vm.Id>>8), byte(vm.Id>>0))
}

func (vm *VM) MAC() net.HardwareAddr {
	return net.HardwareAddr([]byte{0, 0, 10, byte(vm.Id >> 16), byte(vm.Id >> 8), byte(vm.Id >> 0)})
}

func (vm *VM) Uid() int {
	return vm.Id << 8
}

func (vm *VM) Username() string {
	return vm.Name
}

func (vm *VM) Hostname() string {
	return "koding-" + vm.Username()
}

func (vm *VM) RbdDevice() string {
	return "/dev/rbd/rbd/" + vm.String()
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

func FetchUnused() *VM {
	var vm VM
	_, err := VMs.Find(bson.M{"used": false}).Limit(1).Apply(mgo.Change{Update: bson.M{"used": true}, ReturnNew: true}, &vm)
	if err == nil {
		return &vm // existing unused VM found
	}
	if err != mgo.ErrNotFound {
		panic(err)
	}

	// create new vm
	var c Counter
	if _, err := Counters.FindId("vmId").Apply(mgo.Change{Update: bson.M{"$inc": bson.M{"v": 1}}}, &c); err != nil {
		panic(err)
	}
	vm = VM{Id: c.Value, Used: true}

	// create disk and map to pool
	if err := exec.Command("/usr/bin/rbd", "create", vm.String(), "--size", "1200").Run(); err != nil {
		panic(err)
	}
	if err = exec.Command("/usr/bin/rbd", "map", vm.String(), "--pool", "rbd").Run(); err != nil {
		panic(err)
	}

	// wait for device to appear
	for {
		_, err := os.Stat(vm.RbdDevice())
		if err == nil {
			break
		}
		if !os.IsNotExist(err) {
			panic(err)
		}
		time.Sleep(time.Second / 2)
	}

	if err := VMs.Insert(vm); err != nil {
		panic(err)
	}

	return &vm
}

func (vm *VM) Prepare(format bool) {
	// prepare directories
	vm.PrepareDir(vm.File(""), 0)
	vm.PrepareDir(vm.File("rootfs"), VMROOT_ID)
	vm.PrepareDir(vm.UpperdirFile("/"), VMROOT_ID)

	// write LXC files
	vm.GenerateFile("config", false)
	vm.GenerateFile("fstab", false)

	if format {
		// create file system
		if err := exec.Command("mkfs.ext4", vm.RbdDevice()).Run(); err != nil {
			panic(err)
		}
	}

	// mount rbd/ceph
	if err := exec.Command("/bin/mount", vm.RbdDevice(), vm.UpperdirFile("")).Run(); err != nil {
		panic(err)
	}

	// prepare directories in upperdir
	vm.PrepareDir(vm.UpperdirFile("/"), VMROOT_ID)           // for chown
	vm.PrepareDir(vm.UpperdirFile("/lost+found"), VMROOT_ID) // for chown
	vm.PrepareDir(vm.UpperdirFile("/etc"), VMROOT_ID)
	vm.PrepareDir(vm.UpperdirFile("/home"), VMROOT_ID)
	vm.PrepareDir(vm.UpperdirFile("/home/"+vm.Username()), vm.Uid())

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

	// mount overlayfs
	if err := exec.Command("/bin/mount", "--no-mtab", "-t", "overlayfs", "-o", fmt.Sprintf("lowerdir=%s,upperdir=%s", LowerdirFile("/"), vm.UpperdirFile("/")), "overlayfs", vm.File("rootfs")).Run(); err != nil {
		panic(err)
	}
}

func (vm *VM) Unprepare() {
	exec.Command("/bin/umount", vm.File("rootfs")).Run()
	exec.Command("/bin/umount", vm.UpperdirFile("")).Run()
	os.Remove(vm.File("config"))
	os.Remove(vm.File("fstab"))
	os.Remove(vm.File("rootfs"))
	os.Remove(vm.UpperdirFile("/"))
	os.Remove(vm.File(""))
}

func (vm *VM) PrepareDir(path string, id int) {
	if err := os.Mkdir(path, 0755); err != nil && !os.IsExist(err) {
		panic(err)
	}
	if id != 0 {
		if err := os.Chown(path, id, id); err != nil {
			panic(err)
		}
	}
}

func (vm *VM) GenerateFile(name string, executable bool) {
	file, err := os.Create(vm.File(name))
	if err != nil {
		panic(err)
	}
	defer file.Close()

	if err := templates.ExecuteTemplate(file, name, vm); err != nil {
		panic(err)
	}

	if executable {
		err = file.Chmod(0755)
	} else {
		err = file.Chmod(0644)
	}
	if err != nil {
		panic(err)
	}
}
