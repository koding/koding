package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	uuid "github.com/nu7hatch/gouuid"
	"io"
	"io/ioutil"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/os/ldapserver"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/tools/config"
	"koding/tools/utils"
	"koding/virt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"net"
	"os"
	"os/exec"
	"path"
	"strconv"
	"strings"
	"sync"
	"time"
)

type Provision struct{}

var (
	region           = "vagrant"
	firstContainerIP net.IP
	containerSubnet  *net.IPNet
	infos            = make(map[bson.ObjectId]*VMInfo)
	infosMutex       sync.Mutex
	port             = flag.String("port", "4003", "port to bind itself")
	ip               = flag.String("ip", "", "ip to bind itself")
	templateDir      = config.Current.ProjectRoot + "/go/templates"
	logWarning       = func(msg string, args ...interface{}) { fmt.Printf(msg, args) }
)

func main() {
	flag.Parse()
	options := &protocol.Options{
		LocalIP:  *ip,
		PublicIP: "localhost",
		Username: "fatih",
		Kitename: "os-local",
		Version:  "0.0.1",
		Port:     *port,
	}

	methods := map[string]string{
		"vm.start":          "Start",
		"vm.shutdown":       "Shutdown",
		"vm.stop":           "Stop",
		"vm.reinitialize":   "Reinitialize",
		"vm.info":           "Info",
		"vm.resizeDisk":     "ResizeDisk",
		"vm.createSnapshot": "CreateSnapshot",
		"spawn":             "Spawn",
		"exec":              "Exec",
		"vm.copy":           "Copy",
		"vm.create":         "Create",
	}

	go ldapserver.Listen()
	go initializeVMS()
	go limiterLoop()

	k := kite.New(options)
	k.AddMethods(new(Provision), methods)

	fmt.Println("kite started")
	k.Start()
}

func initializeVMS() {
	fmt.Println("initializing VM's")
	var err error
	if firstContainerIP, containerSubnet, err = net.ParseCIDR(config.Current.ContainerSubnet); err != nil {
		fmt.Println(err)
		return
	}

	virt.VMPool = config.Current.VmPool
	if err := virt.LoadTemplates(templateDir); err != nil {
		fmt.Printf("could not load template dir '%s', err '%s'", templateDir, err)
		os.Exit(1)
		return
	}

	dirs, err := ioutil.ReadDir("/var/lib/lxc")
	if err != nil {
		fmt.Println("exit: dir /var/lib/lxc/ does not exist")
		os.Exit(1)
		return
	}

	// remove and unprepare any vm in the lxc dir that doesn't have any
	// associated document which in mongodb.
	for _, dir := range dirs {
		if strings.HasPrefix(dir.Name(), "vm-") {
			vmId := bson.ObjectIdHex(dir.Name()[3:])
			var vm virt.VM
			query := func(c *mgo.Collection) error {
				return c.FindId(vmId).One(&vm)
			}

			if err := mongodb.Run("jVMs", query); err != nil || vm.HostKite == "" {
				if err := virt.UnprepareVM(vmId); err != nil {
					fmt.Println("unprepareVM error:", err)
				}
				continue
			}

			fmt.Println("VM HOSTKITE", vm.HostKite)
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

func (Provision) Info(r *protocol.KiteDnodeRequest, result *VMInfo) error {
	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	infosMutex.Lock()
	defer infosMutex.Unlock()
	info, ok := infos[vos.VM.Id]
	if !ok {
		return fmt.Errorf("info not available currently", r.Hostname)
	}

	info.State = vos.VM.GetState()

	*result = *info
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
	var command []string
	if r.Args.Unmarshal(&command) != nil {
		return errors.New("[array of strings]")
	}

	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	out, err := vos.VM.AttachCommand(vos.User.Uid, "", command...).CombinedOutput()
	if err != nil {
		return err
	}

	*result = out
	return nil
}

func (Provision) Exec(r *protocol.KiteDnodeRequest, result *[]byte) error {
	var line string
	if r.Args.Unmarshal(&line) != nil {
		return errors.New("excepted [string]")
	}

	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	out, err := vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line).CombinedOutput()
	if err != nil {
		return err
	}

	*result = out
	return nil
}

func (Provision) Copy(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		HostPath  string
		GuestPath string
	}

	if r.Args.Unmarshal(&params) != nil || params.HostPath == "" || params.GuestPath == "" {
		return errors.New("{ hostPath: [string], guestPath: [string]}")
	}

	fmt.Println("Copy called", params)

	vos, err := getVos(r.Username, r.Hostname)
	if err != nil {
		return err
	}

	if !vos.Permissions.Sudo {
		return fmt.Errorf("permission denied: '%s' '%s'", r.Username, r.Hostname)
	}

	err = copyIntoVos(params.HostPath, params.GuestPath, vos)
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (Provision) Create(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Reinitialize bool
		VmName       string
	}

	if r.Args.Unmarshal(&params) != nil || params.VmName == "" {
		return errors.New("{ vmName: [string]}")
	}

	fmt.Println("Create called", params)

	err := createVM(params.VmName, params.Reinitialize)
	if err != nil {
		return err
	}

	*result = true
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

	err = validateUser(user)
	if err != nil {
		return nil, err
	}

	err = validateVM(vm)
	if err != nil {
		return nil, err
	}

	if p := vm.GetPermissions(user); p == nil {
		return nil, fmt.Errorf("user '%s' with uid '%d' doesn't have permission", user.Name, user.Uid)
	}

	err = prepareVM(user, vm)
	if err != nil {
		return nil, err
	}

	err = prepareHomeDirs(user, vm)
	if err != nil {
		return nil, err
	}

	return vm.OS(user)
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

func validateVM(vm *virt.VM) error {
	vm.ApplyDefaults()

	if vm.Region != region {
		time.Sleep(time.Second) // to avoid rapid cycle channel loop
		return fmt.Errorf("VM '%s' is on wrong region. Excepted: '%s' Got: '%s'", vm.HostnameAlias, vm.Region, config.Region)
	}

	if vm.HostKite == "(maintenance)" {
		return fmt.Errorf("VM '%s' is under maintenance", vm.HostnameAlias)
	}

	if vm.IP == nil {
		vm.IP = createVMIP()
		err := updateVMIP(vm.IP, vm.Id)
		if err != nil {
			return err
		}
	}

	if !containerSubnet.Contains(vm.IP) {
		return fmt.Errorf("VM with IP is not in the container subnet: %s", vm.IP.String())
	}

	if vm.LdapPassword == "" {
		vm.LdapPassword = createLdapPassword()
		err := updateLdapPassword(vm.LdapPassword, vm.Id)
		if err != nil {
			return err
		}
	}

	return nil
}

func validateUser(user *virt.User) error {
	if user.Uid < virt.UserIdOffset {
		return fmt.Errorf("User %s with too low uid: %s\n", user.Name, user.Uid)
	}

	return nil
}

func createVMIP() net.IP {
	ipInt := nextCounterValue("vm_ip", int(binary.BigEndian.Uint32(firstContainerIP.To4())))
	ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))
	return ip
}

func updateVMIP(ip net.IP, id bson.ObjectId) error {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}})
	}

	if err := mongodb.Run("jVMs", query); err != nil {
		return fmt.Errorf("updateVMIP failed: %s", err)
	}
	return nil
}

func createLdapPassword() string {
	return utils.RandomString()
}

func updateLdapPassword(ldapPassword string, id bson.ObjectId) error {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": id}, bson.M{"$set": bson.M{"ldapPassword": ldapPassword}})
	}

	if err := mongodb.Run("jVMs", query); err != nil {
		return fmt.Errorf("updateLdapPassword failed: %s", err)
	}

	return nil
}

func prepareVM(user *virt.User, vm *virt.VM) error {
	isPrepared := true
	if _, err := os.Stat(vm.File("rootfs/dev")); err != nil {
		if !os.IsNotExist(err) {
			return err
		}
		isPrepared = false
	}

	infosMutex.Lock()
	defer infosMutex.Unlock()
	info, found := infos[vm.Id]
	if !found {
		info = newInfo(vm)
		infos[vm.Id] = info
	}

	info.useCounter += 1
	info.timeout.Stop()

	if !isPrepared || info.currentHostname != vm.HostnameAlias {
		setupVagrantIPTable(vm)

		// protect vm.Prepare with a mutex(), fsck.ext4 is not concurrent ready
		vm.Prepare(false, logWarning)
		if err := vm.Start(); err != nil {
			return err
		}
	}

	return nil
}

func prepareHomeDirs(user *virt.User, vm *virt.VM) error {
	vmWebDir := "/home/" + vm.WebHome + "/Web"
	userWebDir := userWebDir(user.Name)

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

	err = preparePublicKey(userVos)
	if err != nil {
		return err
	}

	err = prepareKites(user, rootVos)
	if err != nil {
		return err
	}

	return nil
}

func userWebDir(name string) string {
	return userHomeDir(name) + "/Web"
}

func userHomeDir(name string) string {
	return "/home/" + name
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

		ldapserver.ClearCache()
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

func preparePublicKey(vos *virt.VOS) error {
	var err error
	kodingKey := new(models.KodingKeys)
	kodingKey, err = modelhelper.GetKodingKeysByUsername(vos.User.Name, vos.VM.HostnameAlias)
	if err != nil {
		// create a new key
		id, _ := uuid.NewV4()
		kodingKey = modelhelper.NewKodingKeys()
		kodingKey.Key = id.String()
		kodingKey.Owner = vos.User.ObjectId.Hex()
		kodingKey.Hostname = vos.VM.HostnameAlias

		err := modelhelper.AddKodingKeys(kodingKey)
		if err != nil {
			return fmt.Errorf("preparePublicKey adding keys '%s'", err)
		}
	}

	homeDir := userHomeDir(vos.User.Name)
	if err := vos.Mkdir(homeDir+"/.kd", 0755); err != nil && !os.IsExist(err) {
		return fmt.Errorf("creating .kd dir '%s'", err)
	}

	publicFile, err := vos.OpenFile(homeDir+"/.kd/koding.key.pub", os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("creating public key '%s'", err)
	}
	defer publicFile.Close()

	return virt.Templates.ExecuteTemplate(publicFile, "publickey", kodingKey.Key)
}

func prepareKites(user *virt.User, vos *virt.VOS) error {
	terminalConf := "terminal-kite.conf"
	terminalFile, err := vos.OpenFile("/etc/init/"+terminalConf, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("opening terminal kite file '%s'", err)
	}
	defer terminalFile.Close()

	err = virt.Templates.ExecuteTemplate(terminalFile, terminalConf, user)
	if err != nil {
		return fmt.Errorf("creatin terminal kite upstart template '%s'", err)
	}

	fsConf := "fs-kite.conf"
	fsFile, err := vos.OpenFile("/etc/init/"+fsConf, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("opening fs kite file '%s'", err)
	}
	defer fsFile.Close()

	err = virt.Templates.ExecuteTemplate(fsFile, fsConf, user)
	if err != nil {
		return fmt.Errorf("creating fs kite upstart template '%s'", err)
	}

	return nil
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

	// TODO: There are some folders called "empty-diretory", look at them.
	if fi.Name() == "empty-directory" {
		// ignored file
	} else if fi.IsDir() {
		fmt.Println("src is a dir:", src, path.Base(src))
		if err := vos.Mkdir(dst, fi.Mode()); err != nil && !os.IsExist(err) {
			return err
		}

		fmt.Println("creating dir for dst:", dst)

		entries, err := sf.Readdirnames(0)
		if err != nil {
			return err
		}
		fmt.Println("entries for src is:", entries)

		for _, entry := range entries {
			if err := copyIntoVos(src+"/"+entry, dst+"/"+entry, vos); err != nil {
				return err
			}
		}

	} else {
		fmt.Println("src is a file:", src)
		df, err := vos.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
		if err != nil {
			return err
		}

		defer df.Close()

		fmt.Printf("copying from '%s' to '%s'", sf.Name(), df.Name())
		if _, err := io.Copy(df, sf); err != nil {
			return err
		}
	}

	return nil
}

func createVM(vmName string, reinitialize bool) error {
	v, err := modelhelper.GetVM(vmName)
	if err != nil {
		fmt.Println("no VM, creatin a new one")
		v = modelhelper.NewVM()
	}

	v.ContainerName = vmName
	v.HostnameAlias = vmName
	v.Region = "vagrant" // backward compability
	v.WebHome = vmName
	v.IP = createVMIP()
	v.LdapPassword = createLdapPassword()

	err = modelhelper.AddVM(&v)
	if err != nil {
		return err
	}

	vm := virt.VM(v)

	err = validateVM(&vm)
	if err != nil {
		return err
	}

	vm.VMRoot, err = os.Readlink("/var/lib/lxc/vmroot/")
	if err != nil {
		vm.VMRoot = "/var/lib/lxc/vmroot/"
	}
	if vm.VMRoot[0] != '/' {
		vm.VMRoot = "/var/lib/lxc/" + vm.VMRoot
	}

	setupVagrantIPTable(&vm)

	// write LXC files
	virt.PrepareDir(vm.File(""), 0)
	vm.GenerateFile(vm.File("config"), "config", 0, false)
	vm.GenerateFile(vm.File("fstab"), "fstab", 0, false)
	vm.GenerateFile(vm.File("ip-address"), "ip-address", 0, false)

	// map rbd image to block device
	if err := vm.MountRBD(vm.OverlayFile("")); err != nil {
		return fmt.Errorf("mount rbd failed:", err)
	}

	// remove all except /home on reinitialize
	if reinitialize {
		entries, err := ioutil.ReadDir(vm.OverlayFile("/"))
		if err != nil {
			return fmt.Errorf("readdir failed", err)
		}
		for _, entry := range entries {
			if entry.Name() != "home" {
				os.RemoveAll(vm.OverlayFile("/" + entry.Name()))
			}
		}
	}

	// prepare overlay
	virt.PrepareDir(vm.OverlayFile("/"), virt.RootIdOffset)           // for chown
	virt.PrepareDir(vm.OverlayFile("/lost+found"), virt.RootIdOffset) // for chown
	virt.PrepareDir(vm.OverlayFile("/etc"), virt.RootIdOffset)
	vm.GenerateFile(vm.OverlayFile("/etc/hostname"), "hostname", virt.RootIdOffset, false)
	vm.GenerateFile(vm.OverlayFile("/etc/hosts"), "hosts", virt.RootIdOffset, false)
	vm.GenerateFile(vm.OverlayFile("/etc/ldap.conf"), "ldap.conf", virt.RootIdOffset, false)
	vm.MergePasswdFile(logWarning)
	vm.MergeGroupFile(logWarning)
	vm.MergeDpkgDatabase()

	// mount overlay
	virt.PrepareDir(vm.File("rootfs"), virt.RootIdOffset)
	if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "aufs", "-o", fmt.Sprintf("noplink,br=%s:%s", vm.OverlayFile("/"), vm.LowerdirFile("/")), "aufs", vm.File("rootfs")).CombinedOutput(); err != nil {
		return commandError("mount overlay failed.", err, out)
	}

	// mount devpts
	virt.PrepareDir(vm.PtsDir(), virt.RootIdOffset)
	if out, err := exec.Command("/bin/mount", "--no-mtab", "-t", "devpts", "-o", "rw,noexec,nosuid,newinstance,gid="+strconv.Itoa(virt.RootIdOffset+5)+",mode=0620,ptmxmode=0666", "devpts", vm.PtsDir()).CombinedOutput(); err != nil {
		return commandError("mount devpts failed.", err, out)
	}

	virt.Chown(vm.PtsDir(), virt.RootIdOffset, virt.RootIdOffset)
	virt.Chown(vm.PtsDir()+"/ptmx", virt.RootIdOffset, virt.RootIdOffset)

	// add ebtables entry to restrict IP and MAC
	if out, err := exec.Command("/sbin/ebtables", "--append", "VMS", "--protocol", "IPv4", "--source", vm.MAC().String(), "--ip-src", vm.IP.String(), "--in-interface", vm.VEth(), "--jump", "ACCEPT").CombinedOutput(); err != nil {
		return commandError("ebtables rule addition failed.", err, out)
	}

	// add a static route so it is redistributed by BGP
	if out, err := exec.Command("/sbin/route", "add", vm.IP.String(), "lxcbr0").CombinedOutput(); err != nil {
		return commandError("adding route failed.", err, out)
	}

	return nil
}

func commandError(message string, err error, out []byte) error {
	return fmt.Errorf("%s\n%s\n%s", message, err.Error(), string(out))
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

// some convenient wrappers around iptables. Needed to expose lxc's outside Vagrant

type iptables struct {
	cmd  string
	args []string
}

func newIPTables() *iptables {
	return &iptables{
		cmd: "/sbin/iptables",
	}
}

func (i *iptables) append(hostPort, guestPort, guestIP string) error {
	args := []string{"-t", "nat", "--append", "PREROUTING", "-p", "tcp", "--dport", hostPort,
		"-j", "DNAT", "--to-destination", guestIP + ":" + guestPort}
	if out, err := exec.Command(i.cmd, args...).CombinedOutput(); err != nil {
		return fmt.Errorf("append iptables err '%s', out: '%s'", err, string(out))
	}
	return nil
}

func (i *iptables) delete(hostPort, guestPort, guestIP string) error {
	args := []string{"-t", "nat", "--delete", "PREROUTING", "-p", "tcp", "--dport", hostPort,
		"-j", "DNAT", "--to-destination", guestIP + ":" + guestPort}
	if out, err := exec.Command(i.cmd, args...).CombinedOutput(); err != nil {
		return fmt.Errorf("delete iptables err '%s', out: '%s'", err, string(out))
	}
	return nil
}

func (i *iptables) check(hostPort, guestPort, guestIP string) error {
	args := []string{"-t", "nat", "--check", "PREROUTING", "-p", "tcp", "--dport", hostPort,
		"-j", "DNAT", "--to-destination", guestIP + ":" + guestPort}
	if out, err := exec.Command(i.cmd, args...).CombinedOutput(); err != nil {
		return fmt.Errorf("delete iptables err '%s', out: '%s'", err, string(out))
	}

	return nil
}

func (i *iptables) flush() error {
	args := []string{"-t", "nat", "--flush", "PREROUTING"}
	if out, err := exec.Command(i.cmd, args...).CombinedOutput(); err != nil {
		return fmt.Errorf("delete iptables err '%s', out: '%s'", err, string(out))
	}

	return nil
}

func setupVagrantIPTable(vm *virt.VM) {
	// These functions should be in vm.Prepare()
	ip := newIPTables()
	ip.flush() //remove all for now

	// Terminal kite, port 4001
	err := ip.check("4001", "4001", vm.IP.String())
	if err != nil { // means it doesn't exist
		ip.append("4001", "4001", vm.IP.String())
	}

	// Fs Kite, port 4002
	err = ip.check("4002", "4002", vm.IP.String())
	if err != nil { // means it doesn't exist
		ip.append("4002", "4002", vm.IP.String())
	}
}
