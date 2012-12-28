package virt

import (
	"fmt"
	"koding/tools/db"
	"koding/tools/utils"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"os/exec"
	"text/template"
	"time"
)

type VM struct {
	Id           int    "_id"
	Name         string "name"
	Users        []int  "users"
	LdapPassword string "ldapPassword"
	IP           net.IP "ip"
}

const VMROOT_ID = 1000000

var templates *template.Template
var VMs *mgo.Collection = db.Collection("jVMs")
var ipPoolFetch, ipPoolRelease = utils.NewIntPool(utils.IPToInt(net.IPv4(172, 16, 0, 1)))

func init() {
	var err error
	templates, err = template.ParseGlob("templates/lxc/*")
	if err != nil {
		panic(err)
	}
}

func FindVM(query interface{}) (*VM, error) {
	var vm VM
	err := VMs.Find(query).One(&vm)
	return &vm, err
}

func FindVMById(id int) (*VM, error) {
	return FindVM(bson.M{"_id": id})
}

func FindVMByIP(a, b, c, d byte) (*VM, error) {
	if a != 10 || b == 0 {
		return nil, fmt.Errorf("Illegal VM address: %d.%d.%d.%d", a, b, c, d)
	}
	return FindVMById(int(b)<<16 + int(c)<<8 + int(d)<<0)
}

func FindVMByName(name string) (*VM, error) {
	return FindVM(bson.M{"name": name})
}

func (vm *VM) String() string {
	return fmt.Sprintf("vm%d", vm.Id)
}

func (vm *VM) MAC() net.HardwareAddr {
	return net.HardwareAddr([]byte{0, 0, byte(vm.Id >> 24), byte(vm.Id >> 16), byte(vm.Id >> 8), byte(vm.Id >> 0)})
}

func (vm *VM) Hostname() string {
	return vm.Name + ".koding.com"
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

func (vm *VM) HasUser(user *User) bool {
	for _, uid := range vm.Users {
		if uid == user.Id {
			return true
		}
	}
	return false
}

func LowerdirFile(path string) string {
	return "/var/lib/lxc/vmroot/rootfs/" + path
}

// may panic
func FetchUnusedVM(user *User) *VM {
	var vm VM
	_, err := VMs.Find(bson.M{"users": bson.M{"$size": 0}}).Limit(1).Apply(mgo.Change{Update: bson.M{"$push": bson.M{"users": user.Id}, "ldapPassword": utils.RandomString()}, ReturnNew: true}, &vm)
	if err == nil {
		return &vm // existing unused VM found
	}
	if err != mgo.ErrNotFound {
		panic(err)
	}

	// create new vm
	vm = VM{Id: db.NextCounterValue("vmId"), Users: []int{user.Id}, LdapPassword: utils.RandomString()}

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

// may panic
func (vm *VM) Prepare(format bool) {
	if vm.IP != nil {
		return
	}
	vm.IP = utils.IntToIP(<-ipPoolFetch)

	// prepare directories
	vm.PrepareDir(vm.File(""), 0)
	vm.PrepareDir(vm.File("rootfs"), VMROOT_ID)
	vm.PrepareDir(vm.UpperdirFile("/"), VMROOT_ID)

	// write LXC files
	vm.GenerateFile(vm.File("config"), "config", 0, false)
	vm.GenerateFile(vm.File("fstab"), "fstab", 0, false)

	if format {
		// create file system
		if err := exec.Command("/sbin/mkfs.ext4", vm.RbdDevice()).Run(); err != nil {
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
	for _, userId := range vm.Users {
		user, err := FindUserById(userId)
		if err != nil {
			panic(err)
		}
		vm.PrepareDir(vm.UpperdirFile("/home/"+user.Name), user.Id)
	}

	// generate upperdir files
	vm.GenerateFile(vm.UpperdirFile("/etc/hostname"), "hostname", VMROOT_ID, false)
	vm.GenerateFile(vm.UpperdirFile("/etc/ldap.conf"), "ldap.conf", VMROOT_ID, false)
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
	if vm.IP != nil {
		ipPoolRelease <- utils.IPToInt(vm.IP)
		vm.IP = nil
	}
}

// may panic
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

// may panic
func (vm *VM) GenerateFile(path, template string, id int, executable bool) {
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	if err := templates.ExecuteTemplate(file, template, vm); err != nil {
		panic(err)
	}

	if id != 0 {
		if err := file.Chown(id, id); err != nil {
			panic(err)
		}
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
