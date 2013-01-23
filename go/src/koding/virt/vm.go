package virt

import (
	"fmt"
	"io"
	"io/ioutil"
	"koding/tools/db"
	"koding/tools/utils"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"os/exec"
	"syscall"
	"text/template"
	"time"
)

type VM struct {
	Id           bson.ObjectId `bson:"_id"`
	Name         string        `bson:"name"`
	Users        []*UserEntry  `bson:"users"`
	LdapPassword string        `bson:"ldapPassword"`
	IP           net.IP        `bson:"ip"`
}

type UserEntry struct {
	Id   int  `bson:"id"`
	Sudo bool `bson:"sudo"`
}

const VMROOT_ID = 1000000

var templates *template.Template
var VMs *mgo.Collection = db.Collection("jVMs")
var ipPoolFetch, ipPoolRelease = utils.NewIntPool(utils.IPToInt(net.IPv4(10, 0, 0, 2)))

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

func FindVMById(id bson.ObjectId) (*VM, error) {
	return FindVM(bson.M{"_id": id})
}

func FindVMByName(name string) (*VM, error) {
	return FindVM(bson.M{"name": name})
}

// may panic
func GetDefaultVM(user *db.User) *VM {
	if user.DefaultVM == "" {
		vm := FetchUnusedVM(user)

		// create file system
		vm.MapRBD()
		if err := exec.Command("/sbin/mkfs.ext4", vm.RbdDevice()).Run(); err != nil {
			panic(err)
		}

		vm.Name = user.Name
		vm.LdapPassword = utils.RandomString()
		if err := VMs.UpdateId(vm.Id, bson.M{"$set": bson.M{"name": vm.Name, "ldapPassword": vm.LdapPassword}}); err != nil {
			panic(err)
		}

		if err := db.Users.Update(bson.M{"_id": user.Id, "defaultVM": nil}, bson.M{"$set": bson.M{"defaultVM": vm.Id}}); err != nil {
			panic(err)
		}
		user.DefaultVM = vm.Id

		return vm
	}

	vm, err := FindVMById(user.DefaultVM)
	if err != nil {
		panic(err)
	}
	return vm
}

func (vm *VM) String() string {
	return "vm-" + vm.Id.Hex()
}

func (vm *VM) VEth() string {
	return fmt.Sprintf("veth-%x", []byte(vm.IP[12:16]))
}

func (vm *VM) MAC() net.HardwareAddr {
	return net.HardwareAddr([]byte{0, 0, vm.IP[12], vm.IP[13], vm.IP[14], vm.IP[15]})
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

func (vm *VM) GetUserEntry(user *db.User) *UserEntry {
	for _, entry := range vm.Users {
		if entry.Id == user.Id {
			return entry
		}
	}
	return nil
}

func LowerdirFile(path string) string {
	return "/var/lib/lxc/vmroot/rootfs/" + path
}

// may panic
func FetchUnusedVM(user *db.User) *VM {
	var vm VM
	_, err := VMs.Find(bson.M{"users": bson.M{"$size": 0}}).Limit(1).Apply(mgo.Change{Update: bson.M{"$push": bson.M{"users": bson.M{"id": user.Id, "sudo": true}}}, ReturnNew: true}, &vm)
	if err == nil {
		return &vm // existing unused VM found
	}
	if err != mgo.ErrNotFound {
		panic(err)
	}

	// create new vm
	vm = VM{Id: bson.NewObjectId(), Users: []*UserEntry{&UserEntry{Id: user.Id, Sudo: true}}}
	if err := VMs.Insert(bson.M{"_id": vm.Id, "users": vm.Users}); err != nil {
		panic(err)
	}

	return &vm
}

// may panic
func (vm *VM) MapRBD() {
	// map image to block device
	if err := exec.Command("/usr/bin/rbd", "map", vm.String(), "--pool", "rbd").Run(); err != nil {
		exitError, isExitError := err.(*exec.ExitError)
		if !isExitError || exitError.Sys().(syscall.WaitStatus).ExitStatus() != 1 {
			panic(err)
		}

		// create disk and try to map again
		if err := exec.Command("/usr/bin/rbd", "create", vm.String(), "--size", "1200").Run(); err != nil {
			panic(err)
		}
		if err := exec.Command("/usr/bin/rbd", "map", vm.String(), "--pool", "rbd").Run(); err != nil {
			panic(err)
		}
	}

	// wait for block device to appear
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
}

// may panic
func (vm *VM) Prepare() {
	vm.Unprepare()

	ip := utils.IntToIP(<-ipPoolFetch)
	if err := VMs.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}}); err != nil {
		ipPoolRelease <- utils.IPToInt(ip)
		panic(err)
	}
	vm.IP = ip

	// prepare directories
	vm.PrepareDir(vm.File(""), 0)
	vm.PrepareDir(vm.File("rootfs"), VMROOT_ID)
	vm.PrepareDir(vm.UpperdirFile("/"), VMROOT_ID)

	// write LXC files
	vm.GenerateFile(vm.File("config"), "config", 0, false)
	vm.GenerateFile(vm.File("fstab"), "fstab", 0, false)

	// mount rbd/ceph
	vm.MapRBD()
	if err := exec.Command("/bin/mount", vm.RbdDevice(), vm.UpperdirFile("")).Run(); err != nil {
		panic(err)
	}

	// prepare directories in upperdir
	vm.PrepareDir(vm.UpperdirFile("/"), VMROOT_ID)           // for chown
	vm.PrepareDir(vm.UpperdirFile("/lost+found"), VMROOT_ID) // for chown
	vm.PrepareDir(vm.UpperdirFile("/etc"), VMROOT_ID)
	vm.PrepareDir(vm.UpperdirFile("/home"), VMROOT_ID)

	// create user homes
	for i, entry := range vm.Users {
		user, err := db.FindUserById(entry.Id)
		if err != nil {
			panic(err)
		}
		if vm.PrepareDir(vm.UpperdirFile("/home/"+user.Name), user.Id) && i == 0 {
			vm.PrepareDir(vm.UpperdirFile("/home/"+user.Name+"/Sites"), user.Id)
			vm.PrepareDir(vm.UpperdirFile("/home/"+user.Name+"/Sites/"+vm.Hostname()), user.Id)
			websiteDir := "/home/" + user.Name + "/Sites/" + vm.Hostname() + "/website"
			vm.PrepareDir(vm.UpperdirFile(websiteDir), user.Id)
			files, err := ioutil.ReadDir("templates/website")
			if err != nil {
				panic(err)
			}
			for _, file := range files {
				CopyFile("templates/website/"+file.Name(), vm.UpperdirFile(websiteDir+"/"+file.Name()), user.Id)
			}
			vm.PrepareDir(vm.UpperdirFile("/var"), VMROOT_ID)
			if err := os.Symlink(websiteDir, vm.UpperdirFile("/var/www")); err != nil {
				panic(err)
			}
		}
	}

	// generate upperdir files
	vm.GenerateFile(vm.UpperdirFile("/etc/hostname"), "hostname", VMROOT_ID, false)
	vm.GenerateFile(vm.UpperdirFile("/etc/hosts"), "hosts", VMROOT_ID, false)
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
	vm.StopCommand().Run()
	exec.Command("/bin/umount", vm.File("rootfs")).Run()
	exec.Command("/bin/umount", vm.UpperdirFile("")).Run()
	exec.Command("/usr/bin/rbd", "unmap", vm.String(), "--pool", "rbd").Run()
	os.Remove(vm.File("config"))
	os.Remove(vm.File("fstab"))
	os.Remove(vm.File("rootfs"))
	os.Remove(vm.UpperdirFile("/"))
	os.Remove(vm.File(""))
	if vm.IP != nil {
		VMs.UpdateId(vm.Id, bson.M{"$set": bson.M{"ip": nil}})
		ipPoolRelease <- utils.IPToInt(vm.IP)
		vm.IP = nil
	}
}

// may panic
func (vm *VM) PrepareDir(path string, id int) bool {
	created := true
	if err := os.Mkdir(path, 0755); err != nil {
		if os.IsExist(err) {
			created = false
		} else {
			panic(err)
		}
	}

	if err := os.Chown(path, id, id); err != nil {
		panic(err)
	}

	return created
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

	if err := file.Chown(id, id); err != nil {
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

// may panic
func CopyFile(src, dst string, id int) {
	sf, err := os.Open(src)
	if err != nil {
		panic(err)
	}
	defer sf.Close()

	df, err := os.Create(dst)
	if err != nil {
		panic(err)
	}

	defer sf.Close()
	if _, err := io.Copy(df, sf); err != nil {
		panic(err)
	}

	if err := df.Chown(id, id); err != nil {
		panic(err)
	}
}
