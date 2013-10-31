// +build linux

package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/supervisor/container"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/tools/config"
	"koding/tools/utils"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"net"
	"time"
)

type Supervisor struct{}

var (
	port             = flag.String("port", "4005", "port to bind itself")
	containerSubnet  *net.IPNet
	firstContainerIP net.IP
)

func main() {
	flag.Parse()
	options := &protocol.Options{
		PublicIP: "localhost",
		Kitename: "supervisor",
		Version:  "0.0.1",
		Port:     *port,
	}

	methods := map[string]string{
		"vm.create":    "Create",
		"vm.destroy":   "Destroy",
		"vm.start":     "Start",
		"vm.stop":      "Stop",
		"vm.shutdown":  "Shutdown",
		"vm.prepare":   "Prepare",
		"vm.unprepare": "Unprepare",
	}

	initialize()

	k := kite.New(options)
	k.AddMethods(new(Supervisor), methods)
	k.Start()
}

func initialize() {
	var err error
	if firstContainerIP, containerSubnet, err = net.ParseCIDR(config.Current.ContainerSubnet); err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println("initialized")
}

func (s *Supervisor) Create(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
		Template      string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.Template == "" {
		return errors.New("{ containerName: [string], template: [string] }")
	}

	fmt.Printf("creating vm '%s' with template '%s'\n",
		params.ContainerName, params.Template)

	c := container.NewContainer(params.ContainerName)
	err := c.Create(params.Template)
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Destroy(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	fmt.Println("destroying", params.ContainerName)
	c := container.NewContainer(params.ContainerName)
	err := c.Destroy()
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Start(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	fmt.Println("starting", params.ContainerName)
	c := container.NewContainer(params.ContainerName)
	err := c.Start()
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Stop(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	fmt.Println("stopping", params.ContainerName)
	c := container.NewContainer(params.ContainerName)
	err := c.Stop()
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Shutdown(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
		Timeout       int
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.Timeout == 0 {
		return errors.New("{ containerName: [string], timeout : [int]}")
	}

	fmt.Println("shutdown", params.ContainerName)
	c := container.NewContainer(params.ContainerName)
	err := c.Shutdown(params.Timeout)
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Run(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
		Command       string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" || params.Command == "" {
		return errors.New("{ containerName: [string], command : [string]}")
	}

	fmt.Printf("running '%s' on '%s'\n", params.Command, params.Command)
	c := container.NewContainer(params.ContainerName)
	err := c.Run(params.Command)
	if err != nil {
		return err
	}

	return nil
}

func (s *Supervisor) Unprepare(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	vm, err := getVM(r.Hostname)
	if err != nil {
		return err
	}

	err = validateVM(vm)
	if err != nil {
		return err
	}

	fmt.Printf("unpreparing container '%s'\n", params.ContainerName)
	c := container.NewContainer(params.ContainerName)

	// these values are needed for templating. will be changed later
	// with a template struct.
	c.IP = vm.IP

	err = c.Unprepare()
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (s *Supervisor) Prepare(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		ContainerName string
	}

	if r.Args.Unmarshal(&params) != nil || params.ContainerName == "" {
		return errors.New("{ containerName: [string] }")
	}

	user, err := getUser(r.Username)
	if err != nil {
		return err
	}

	vm, err := getVM(r.Hostname)
	if err != nil {
		return err
	}

	err = validateVM(vm)
	if err != nil {
		return err
	}

	err = validateUser(user)
	if err != nil {
		return err
	}

	fmt.Printf("preparing container '%s'\n", params.ContainerName)
	c := container.NewContainer(params.ContainerName)

	// these values are needed for templating. will be changed later
	// with a template struct.
	c.IP = vm.IP
	c.LdapPassword = vm.LdapPassword
	c.HostnameAlias = vm.HostnameAlias
	c.WebHome = vm.WebHome
	c.Username = user.Name
	c.Useruid = user.Uid

	err = c.Prepare()
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func getUser(username string) (*models.User, error) {
	if username == "" {
		return nil, errors.New("username is empty")
	}

	return modelhelper.GetUser(username)
}

func getVM(hostnameAlias string) (*models.VM, error) {
	if hostnameAlias == "" {
		return nil, errors.New("hostname is empty")
	}

	return modelhelper.GetVM(hostnameAlias)
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
		return fmt.Errorf("VM '%s' is on wrong region. Excepted: '%s' Got: '%s'",
			vm.HostnameAlias, vm.Region, config.Region)
	}

	if vm.HostKite == "(maintenance)" {
		return fmt.Errorf("VM '%s' is under maintenance", vm.HostnameAlias)
	}

	if vm.HostKite == "(banned)" {
		return fmt.Errorf("VM '%s' is banned", vm.HostnameAlias)
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
