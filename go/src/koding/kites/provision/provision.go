package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/tools/config"
	"koding/tools/utils"
	"koding/virt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"strings"
	"sync"
	"time"
)

type Provision struct {
	ProgramName string
}

var (
	infos       = make(map[bson.ObjectId]*VMInfo)
	infosMutex  sync.Mutex
	port        = flag.String("port", "4000", "port to bind itself")
	ip          = flag.String("ip", "0.0.0.0", "ip to bind itself")
	templateDir = config.Current.ProjectRoot + "/go/templates"
)

func main() {
	flag.Parse()
	o := &protocol.Options{
		LocalIP:  *ip,
		Username: "fatih",
		Kitename: "provision",
		Version:  "1",
		Port:     *port,
	}

	methods := map[string]interface{}{
		"vm.start":          Provision.Start,
		"vm.shutdown":       Provision.Shutdown,
		"vm.stop":           Provision.Stop,
		"vm.reinitialize":   Provision.Reinitialize,
		"vm.info":           Provision.Info,
		"vm.resizeDisk":     Provision.ResizeDisk,
		"vm.createSnapshot": Provision.CreateSnapshot,
		"spawn":             Provision.Spawn,
		"exec":              Provision.Exec,
	}

	k := kite.New(o, new(Provision), methods)
	k.Start()
}

func initializeVMS() {
	dirs, err := ioutil.ReadDir("/var/lib/lxc")
	if err != nil {
		fmt.Println("Exiting: dir /var/lib/lxc/ does not exist")
		os.Exit(1)
		return
	}
	for _, dir := range dirs {
		if strings.HasPrefix(dir.Name(), "vm-") {
			vmId := bson.ObjectIdHex(dir.Name()[3:])
			var vm virt.VM
			query := func(c *mgo.Collection) error {
				return c.FindId(vmId).One(&vm)
			}

			if err := mongodb.Run("jVMs", query); err != nil {
				if err := virt.UnprepareVM(vmId); err != nil {
					fmt.Println("unprepareVM error:", err)
				}
				continue
			}
			vm.ApplyDefaults()
			info := newInfo(&vm)
			infos[vm.Id] = info
			info.startTimeout()
		}
	}
}

func (Provision) Start(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	if err := vos.VM.Start(); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) Stop(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	if err := vos.VM.Stop(); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) Shutdown(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	if err := vos.VM.Shutdown(); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) Info(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	infosMutex.Lock()
	info := infos[vos.VM.Id]
	info.State = vos.VM.GetState()
	infosMutex.Unlock()

	*result = true
	return nil
}

func (Provision) Reinitialize(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	logWarning := func(msg string, args ...interface{}) {
		fmt.Printf(msg, args)
	}

	vos.VM.Prepare(true, logWarning)
	if err := vos.VM.Start(); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) ResizeDisk(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	if err := vos.VM.ResizeRBD(); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) CreateSnapshot(r *protocol.KiteDnodeRequest, result *bool) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	if err := vos.VM.ResizeRBD(); err != nil {
		return err
	}

	snippetId := bson.NewObjectId().Hex()
	if err := vos.VM.CreateConsistentSnapshot(snippetId); err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) Spawn(r *protocol.KiteDnodeRequest, result *[]byte) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	var command []string
	if r.Args.Unmarshal(&command) != nil {
		return errors.New("[array of strings]")
	}

	out, err := vos.VM.AttachCommand(vos.User.Uid, "", command...).CombinedOutput()
	if err != nil {
		return err
	}

	*result = out
	return nil
}

func (Provision) Exec(r *protocol.KiteDnodeRequest, result *[]byte) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	var line string
	if r.Args.Unmarshal(&line) != nil {
		return errors.New("[string]")
	}

	out, err := vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line).CombinedOutput()
	if err != nil {
		return err
	}

	*result = out
	return nil
}

/***********************************************

Helper functions

***********************************************/

func getVos(username, hostnameAlias string) (*virt.VOS, error) {
	user, err := getUser(username)
	if err != nil {
		return nil, err
	}

	vm, err := getVM(hostnameAlias)
	if err != nil {
		return nil, err
	}

	err = validateAndSetup(user, vm)
	if err != nil {
		return nil, err
	}

	err = createDirs(user, vm)
	if err != nil {
		return nil, err
	}

	return vm.OS(user)
}

func createDirs(user *virt.User, vm *virt.VM) error {
	isPrepared := true
	if _, err := os.Stat(vm.File("rootfs/dev")); err != nil {
		if !os.IsNotExist(err) {
			return err
		}
		isPrepared = false
	}

	logWarning := func(msg string, args ...interface{}) {
		fmt.Printf(msg, args)
	}

	if !isPrepared {
		vm.Prepare(false, logWarning)
		if err := vm.Start(); err != nil {
			return err
		}
	}

	vmWebDir := "/home/" + vm.WebHome + "/Web"
	userWebDir := "/home/" + user.Name + "/Web"

	rootVos, err := vm.OS(&virt.RootUser)
	if err != nil {
		return err
	}

	userVos, err := vm.OS(user)
	if err != nil {
		return err
	}

	vmWebVos := rootVos
	if vmWebDir == userWebDir {
		vmWebVos = userVos
	}

	rootVos.Chmod("/", 0755)     // make sure that executable flag is set
	rootVos.Chmod("/home", 0755) // make sure that executable flag is set

	createUserHome(user, rootVos, userVos)
	createVmWebDir(vm, vmWebDir, rootVos, vmWebVos)
	if vmWebDir != userWebDir {
		createUserWebDir(user, vmWebDir, userWebDir, rootVos, userVos)
	}

	return nil
}

func getUser(username string) (*virt.User, error) {
	if username == "" {
		return nil, errors.New("username or hostname is empty")
	}

	u, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, err
	}

	user := virt.User(*u)
	return &user, nil
}

func getVM(hostnameAlias string) (*virt.VM, error) {
	v, err := modelhelper.GetVM(hostnameAlias)
	if err != nil {
		return nil, err
	}

	vm := virt.VM(v)

	return &vm, nil
}

func validateAndSetup(user *virt.User, vm *virt.VM) error {
	vm.ApplyDefaults()

	if user.Uid < virt.UserIdOffset {
		return fmt.Errorf("User %s with too low uid: %s\n", user.Name, user.Uid)
	}

	if vm.Region != config.Region {
		time.Sleep(time.Second) // to avoid rapid cycle channel loop
		return fmt.Errorf("VM '%s' is on wrong region. Excepted: '%s' Got: '%s'", vm.HostnameAlias, vm.Region, config.Region)
	}

	if vm.HostKite == "(maintenance)" {
		return fmt.Errorf("VM '%s' is under maintenance", vm.HostnameAlias)
	}

	var firstContainerIP net.IP
	var containerSubnet *net.IPNet
	var err error

	if firstContainerIP, containerSubnet, err = net.ParseCIDR(config.Current.ContainerSubnet); err != nil {
		return err
	}

	if vm.IP == nil {
		ipInt := nextCounterValue("vm_ip", int(binary.BigEndian.Uint32(firstContainerIP.To4())))
		ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))

		query := func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}})
		}

		if err := mongodb.Run("jVMs", query); err != nil {
			return err
		}

		vm.IP = ip
	}

	if !containerSubnet.Contains(vm.IP) {
		return fmt.Errorf("VM with IP that is not in the container subnet: %s", vm.IP.String())
	}

	if vm.LdapPassword == "" {
		ldapPassword := utils.RandomString()

		query := func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"ldapPassword": ldapPassword}})
		}

		if err := mongodb.Run("jVMs", query); err != nil {
			return err
		}

		vm.LdapPassword = ldapPassword
	}

	if p := vm.GetPermissions(user); p == nil {
		return fmt.Errorf("user '%s' with uid '%s' doesn't have permission", user.Name, user.Uid)
	}

	return nil
}

type Counter struct {
	Name  string `bson:"_id"`
	Value int    `bson:"seq"`
}

func nextCounterValue(counterName string, initialValue int) int {
	var counter Counter

	if err := mongodb.Run("counters", func(c *mgo.Collection) error {
		_, err := c.FindId(counterName).Apply(mgo.Change{Update: bson.M{"$inc": bson.M{"seq": 1}}}, &counter)
		return err
	}); err != nil {
		if err == mgo.ErrNotFound {
			mongodb.Run("counters", func(c *mgo.Collection) error {
				c.Insert(Counter{Name: counterName, Value: initialValue})
				return nil // ignore error and try to do atomic update again
			})

			if err := mongodb.Run("counters", func(c *mgo.Collection) error {
				_, err := c.FindId(counterName).Apply(mgo.Change{Update: bson.M{"$inc": bson.M{"seq": 1}}}, &counter)
				return err
			}); err != nil {
				panic(err)
			}
			return counter.Value
		}
		panic(err)
	}

	return counter.Value

}

func createUserHome(user *virt.User, rootVos, userVos *virt.VOS) {
	if info, err := rootVos.Stat("/home/" + user.Name); err == nil {
		rootVos.Chmod("/home/"+user.Name, info.Mode().Perm()|0511) // make sure that user read and executable flag is set
		return
	}
	// home directory does not yet exist

	if _, err := rootVos.Stat("/home/" + user.OldName); user.OldName != "" && err == nil {
		if err := rootVos.Rename("/home/"+user.OldName, "/home/"+user.Name); err != nil {
			panic(err)
		}
		if err := rootVos.Symlink(user.Name, "/home/"+user.OldName); err != nil {
			panic(err)
		}
		if err := rootVos.Chown("/home/"+user.OldName, user.Uid, user.Uid); err != nil {
			panic(err)
		}

		if target, err := rootVos.Readlink("/var/www"); err == nil && target == "/home/"+user.OldName+"/Web" {
			if err := rootVos.Remove("/var/www"); err != nil {
				panic(err)
			}
			if err := rootVos.Symlink("/home/"+user.Name+"/Web", "/var/www"); err != nil {
				panic(err)
			}
		}

		return
	}

	if err := rootVos.MkdirAll("/home/"+user.Name, 0755); err != nil && !os.IsExist(err) {
		panic(err)
	}
	if err := rootVos.Chown("/home/"+user.Name, user.Uid, user.Uid); err != nil {
		panic(err)
	}
	if err := copyIntoVos(templateDir+"/user", "/home/"+user.Name, userVos); err != nil {
		panic(err)
	}
}

func createVmWebDir(vm *virt.VM, vmWebDir string, rootVos, vmWebVos *virt.VOS) {
	if err := rootVos.Symlink(vmWebDir, "/var/www"); err != nil {
		if !os.IsExist(err) {
			panic(err)
		}
		return
	}
	// symlink successfully created

	if _, err := rootVos.Stat(vmWebDir); err == nil {
		return
	}
	// vmWebDir directory does not yet exist

	// migration of old Sites directory
	migrationErr := vmWebVos.Rename("/home/"+vm.WebHome+"/Sites/"+vm.HostnameAlias, vmWebDir)
	vmWebVos.Remove("/home/" + vm.WebHome + "/Sites")
	rootVos.Remove("/etc/apache2/sites-enabled/" + vm.HostnameAlias)

	if migrationErr != nil {
		// create fresh Web directory if migration unsuccessful
		if err := vmWebVos.MkdirAll(vmWebDir, 0755); err != nil {
			panic(err)
		}
		if err := copyIntoVos(templateDir+"/website", vmWebDir, vmWebVos); err != nil {
			panic(err)
		}
	}
}

func createUserWebDir(user *virt.User, vmWebDir, userWebDir string, rootVos, userVos *virt.VOS) {
	if _, err := rootVos.Stat(userWebDir); err == nil {
		return
	}
	// userWebDir directory does not yet exist

	if err := userVos.MkdirAll(userWebDir, 0755); err != nil {
		panic(err)
	}
	if err := copyIntoVos(templateDir+"/website", userWebDir, userVos); err != nil {
		panic(err)
	}
	if err := rootVos.Symlink(userWebDir, vmWebDir+"/~"+user.Name); err != nil && !os.IsExist(err) {
		panic(err)
	}
}

func copyIntoVos(src, dst string, vos *virt.VOS) error {
	sf, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return err
	}

	if fi.Name() == "empty-directory" {
		// ignored file
	} else if fi.IsDir() {
		if err := vos.Mkdir(dst, fi.Mode()); err != nil && !os.IsExist(err) {
			return err
		}

		entries, err := sf.Readdirnames(0)
		if err != nil {
			return err
		}
		for _, entry := range entries {
			if err := copyIntoVos(src+"/"+entry, dst+"/"+entry, vos); err != nil {
				return err
			}
		}
	} else {
		df, err := vos.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
		if err != nil {
			return err
		}
		defer df.Close()

		if _, err := io.Copy(df, sf); err != nil {
			return err
		}
	}

	return nil
}

/***********************************************

VMInfo struct and methods

***********************************************/

type VMInfo struct {
	vm              *virt.VM
	useCounter      int
	timeout         *time.Timer
	mutex           sync.Mutex
	totalCpuUsage   int
	currentCpus     []string
	currentHostname string

	State               string `json:"state"`
	CpuUsage            int    `json:"cpuUsage"`
	CpuShares           int    `json:"cpuShares"`
	MemoryUsage         int    `json:"memoryUsage"`
	PhysicalMemoryLimit int    `json:"physicalMemoryLimit"`
	TotalMemoryLimit    int    `json:"totalMemoryLimit"`
}

func newInfo(vm *virt.VM) *VMInfo {
	return &VMInfo{
		vm:                  vm,
		useCounter:          0,
		timeout:             time.NewTimer(0),
		totalCpuUsage:       utils.MaxInt,
		currentCpus:         nil,
		currentHostname:     vm.HostnameAlias,
		CpuShares:           1000,
		PhysicalMemoryLimit: 100 * 1024 * 1024,
		TotalMemoryLimit:    1024 * 1024 * 1024,
	}
}

func (info *VMInfo) startTimeout() {
	if info.useCounter != 0 || info.vm.AlwaysOn {
		return
	}
	info.timeout = time.AfterFunc(5*time.Minute, func() {
		if info.useCounter != 0 || info.vm.AlwaysOn {
			return
		}
		if info.vm.GetState() == "RUNNING" {
			if err := info.vm.SendMessageToVMUsers("========================================\nThis VM will be turned off in 5 minutes.\nLog in to Koding.com to keep it running.\n========================================\n"); err != nil {
				fmt.Println("Warning: startTimeout error", err)
			}
		}
		info.timeout = time.AfterFunc(5*time.Minute, func() {
			info.mutex.Lock()
			defer info.mutex.Unlock()
			if info.useCounter != 0 || info.vm.AlwaysOn {
				return
			}
			info.unprepareVM()
		})
	})
}

func (info *VMInfo) unprepareVM() {
	if err := virt.UnprepareVM(info.vm.Id); err != nil {
		fmt.Println("Warning: unprepareVM error", err)
	}

	if err := mongodb.Run("jVMs", func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": info.vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
	}); err != nil {
		fmt.Println("Warning:  error", err)
	}

	infosMutex.Lock()
	if info.useCounter == 0 {
		delete(infos, info.vm.Id)
	}
	infosMutex.Unlock()
}
