// +build linux

package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"kite"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/provisioning/container"
	"koding/tools/config"
	"koding/tools/utils"
	"net"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/op/go-logging"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	port             = flag.String("port", "4005", "port to bind itself")
	containerSubnet  *net.IPNet
	firstContainerIP net.IP
	states           = make(map[string]*State)
	statesMu         sync.Mutex
	k                = *kite.Kite
	log              *logging.Logger
)

func init() {
	var err error
	if firstContainerIP, containerSubnet, err = net.ParseCIDR(config.Current.ContainerSubnet); err != nil {
		log.Error("container subnet couldn't be initialized: %s", err.Error())
		os.Exit(1)
	}

	if config.Region == "" {
		log.Error("region is not defined. please define it with -r flag")
		os.Exit(1)
	}
}

func main() {
	flag.Parse()

	options := &kite.Options{
		PublicIP:    "localhost",
		Kitename:    "provisioning",
		Environment: config.FileProfile,
		Region:      config.Region,
		Version:     "0.0.1",
		Port:        *port,
	}

	k = kite.New(options)

	k.HandleFunc("start", Start)
	k.HandleFunc("stop", Stop)
	k.HandleFunc("prepare", Prepare)
	k.HandleFunc("unprepare", Unprepare)
	k.HandleFunc("exec", Exec)
	k.HandleFunc("info", Info)
	k.HandleFunc("state", StateFunc)
	k.HandleFunc("resizeDisk", ResizeDisk)

	k.Run()
}

func Start(r *kite.Request) (interface{}, error) {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return nil, errors.New("{ containerName: [string] }")
	}

	vm, err := getVM(params.ContainerName)
	if err != nil {
		log.Error("[%s] could not get vm to start '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not start vm - 1")
	}

	containerName := "vm-" + vm.Id.Hex()

	c := container.NewContainer(containerName)
	err = c.Start()
	if err != nil {
		log.Error("[%s] could not start container: '%s'. err: '%s'", r.Username, containerName, err)
		return nil, errors.New("could not start vm - 2")
	}

	log.Info("[%s] started the container: '%s'", r.Username, containerName)
	return true, nil
}

func StateFunc(r *kite.Request) (interface{}, error) {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return nil, errors.New("{ containerName: [string] }")
	}

	log.Info("[%s] requested state for the container: '%s'", r.Username, params.ContainerName)

	vm, err := getVM(params.ContainerName)
	if err == nil {
		containerName := "vm-" + vm.Id.Hex()
		c := container.NewContainer(containerName)
		return c.State(), nil
	}

	// the vm could be in a maintenance mode, if yes return the state as "MAINTENANCE"
	_, ok := err.(*UnderMaintenanceError)
	if !ok {
		log.Error("[%s] could not get vm to state '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not state vm - 1")
	}

	return "MAINTENANCE", nil
}

func ResizeDisk(r *kite.Request) (interface{}, error) {
	var params struct {
		ContainerName string
		ResizeTo      int
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.ResizeTo == 0 {
		return nil, errors.New("{ containerName: [string], resizeTo: [int] }")
	}

	log.Info("[%s] resizeDisk the container: '%s'", r.Username, params.ContainerName)

	vm, err := getVM(params.ContainerName)
	if err != nil {
		log.Error("[%s] could not get vm to resize '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not start vm - 1")
	}

	containerName := "vm-" + vm.Id.Hex()
	c := container.NewContainer(containerName)

	err = c.Resize(params.ResizeTo)
	if err != nil {
		return nil, err
	}

	return true, nil
}

func Info(r *kite.Request) (interface{}, error) {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return nil, errors.New("{ containerName: [string] }")
	}

	log.Info("[%s] requested info for the container: '%s'", r.Username, params.ContainerName)

	vm, err := getVM(params.ContainerName)
	if err != nil {
		log.Error("[%s] could not get vm to get info about '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not info vm - 1")
	}

	containerName := "vm-" + vm.Id.Hex()

	state := GetState(containerName)
	return state.ContainerInfo, nil
}

func Stop(r *kite.Request) (interface{}, error) {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return nil, errors.New("{ containerName: [string] }")
	}

	vm, err := getVM(params.ContainerName)
	if err != nil {
		log.Error("[%s] could not get vm to stop '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not stop vm - 1")
	}

	containerName := "vm-" + vm.Id.Hex()

	c := container.NewContainer(containerName)
	err = c.Stop()
	if err != nil {
		log.Error("[%s] could not stop container: '%s'. err: '%s'", r.Username, containerName, err)
		return nil, errors.New("could not stop vm - 2")
	}

	log.Info("[%s] stopped the container: '%s'", r.Username, containerName)
	return true, nil
}

func Exec(r *kite.Request) (interface{}, error) {
	var params struct {
		ContainerName string
		Command       string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.Command == "" {
		return nil, errors.New("{ containerName: [string] , command: [string] }")
	}

	user, err := getUser(r.Username)
	if err != nil {
		log.Error("[%s] could not get user to exec a command on '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not run command - 1")
	}

	vm, err := getVM(params.ContainerName)
	if err != nil {
		log.Error("[%s] could not get vm to exec a command on '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not run command - 2")
	}

	containerName := "vm-" + vm.Id.Hex()

	c := container.NewContainer(containerName)
	c.Useruid = user.Uid

	output, err := c.Run(params.Command)
	if err != nil {
		log.Error("[%s] could not exec a command on '%s'. err: '%s'", r.Username, params.ContainerName, err)
		return nil, errors.New("could not run command - 3")
	}

	state := GetState(containerName)
	state.ResetTimer()
	log.Info("[%s] did run the command '%s' on container %s\n", r.Username, params.Command, containerName)

	return string(output), nil
}

func Unprepare(r *kite.Request) (interface{}, error) {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return nil, errors.New("{ containerName: [string] }")
	}

	vm, err := getVM(params.ContainerName)
	if err != nil {
		log.Error("[%s] could not get vm to unprepare '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not unprepare vm - 1")
	}

	containerName := "vm-" + vm.Id.Hex()

	c := container.NewContainer(containerName)
	c.IP = vm.IP // needed for removing static route and ebtables in unprepare

	if c.IsRunning() {
		err = c.Shutdown(5)
		if err != nil {
			log.Error("[%s] could not shutdown vm for unprepare vm: '%s'. err: '%s'",
				r.Username, params.ContainerName, err)
			return nil, errors.New("could not unprepare vm - 2")
		}
	}

	err = c.Unprepare()
	if err != nil {
		log.Error("[%s] could not unprepare vm: '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not unprepare vm - 3")
	}

	log.Info("[%s] unprepared the container '%s'", r.Username, containerName)
	return true, nil
}

func Prepare(r *kite.Request) (interface{}, error) {
	var params struct {
		ContainerName string
		Reinitialize  bool
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return nil, errors.New("{ containerName: [string] }")
	}

	err := prepare(params.Reinitialize, params.ContainerName, r)
	if err != nil {
		log.Error("[%s] could not prepare vm: '%s'. err: '%s'",
			r.Username, params.ContainerName, err)
		return nil, errors.New("could not prepare vm")
	}

	return true, nil
}

func prepare(reinitialize bool, vmName string, r *kite.Request) error {
	username := r.Username

	user, err := getUser(username)
	if err != nil {
		return err
	}

	vm, err := getVM(vmName)
	if err != nil {
		return err
	}

	containerName := "vm-" + vm.Id.Hex()
	c := container.NewContainer(containerName)

	if c.IsRunning() {
		return errors.New("vm is running")
	}

	// these values are needed for templating. will be changed later
	// with a template struct.
	c.IP = vm.IP
	c.LdapPassword = vm.LdapPassword
	c.HostnameAlias = vm.HostnameAlias
	c.WebHome = vm.WebHome
	c.Username = user.Name
	c.Useruid = user.Uid
	c.DiskSizeInMB = vm.DiskSizeInMB

	log.Info("preparing container '%s' for user '%s' with uid '%d' (reinitializing: %t)",
		containerName, user.Name, user.Uid, reinitialize)

	err = c.Prepare(reinitialize)
	if err != nil {
		return err
	}

	err = c.Start()
	if err != nil {
		return err
	}

	if vm.AlwaysOn {
		return nil
	}

	state := GetState(containerName)
	state.IP = c.IP
	state.StartTimer()
	r.RemoteKite.OnDisconnect(func() {
		state.StopTimer()
	})

	log.Info("[%s] prepared the container '%s'", username, containerName)
	return nil
}

func getUser(username string) (*models.User, error) {
	if username == "" {
		return nil, errors.New("username is empty")
	}

	user, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, err
	}

	err = validateUser(user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func getVM(hostnameAlias string) (*models.VM, error) {
	if hostnameAlias == "" {
		return nil, errors.New("hostname is empty")
	}

	vm, err := modelhelper.GetVM(hostnameAlias)
	if err != nil {
		return nil, err
	}

	err = validateVM(vm)
	if err != nil {
		return nil, err
	}

	return vm, nil
}

type UnderMaintenanceError struct{}

func (err *UnderMaintenanceError) Error() string {
	return "VM is under maintenance."
}

type AccessDeniedError struct{}

func (err *AccessDeniedError) Error() string {
	return "Vm is banned"
}

func validateVM(vm *models.VM) error {
	// applyDefaults
	if vm.NumCPUs == 0 {
		vm.NumCPUs = 1
	}
	if vm.MaxMemoryInMB == 0 {
		vm.MaxMemoryInMB = 1024
	}
	if vm.DiskSizeInMB == 0 {
		vm.DiskSizeInMB = 1200
	}

	if vm.Region != config.Region {
		time.Sleep(time.Second) // to avoid rapid cycle channel loop
		return fmt.Errorf("VM '%s' is on wrong region. expected: '%s' Got: '%s'",
			vm.HostnameAlias, config.Region, vm.Region)
	}

	if vm.HostKite == "(maintenance)" {
		log.Info("VM '%s' is under maintenance", vm.HostnameAlias)
		return new(UnderMaintenanceError)
	}

	if vm.HostKite == "(banned)" {
		log.Info("VM '%s' is banned", vm.HostnameAlias)
		return new(AccessDeniedError)
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

func validateUser(user *models.User) error {
	if user.Uid < container.UserUIDOffset {
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
