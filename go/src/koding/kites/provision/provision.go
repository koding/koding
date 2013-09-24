package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
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
)

type Provision struct {
	ProgramName string
}

var (
	port = flag.String("port", "4000", "port to bind itself")
	ip   = flag.String("ip", "0.0.0.0", "ip to bind itself")
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
	}

	k := kite.New(o, new(Provision), methods)
	k.Start()
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
	//TODO: implement this
	// info := channel.KiteData.(*VMInfo)
	// info.State = getState(name)

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

/***********************************************

Helper functions

***********************************************/

func getUser(username string) (*virt.User, error) {
	if username == "" {
		return nil, errors.New("username or hostname is empty")
	}

	u, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, err
	}

	user := virt.User(*u)

	if user.Uid < virt.UserIdOffset {
		return nil, fmt.Errorf("User %s with too low uid: %s\n", user.Name, user.Uid)
	}

	return &user, nil
}

func getVm(hostnameAlias string) (*virt.VM, error) {
	v, err := modelhelper.GetVM(hostnameAlias)
	if err != nil {
		return nil, err
	}

	vm := virt.VM(v)
	vm.ApplyDefaults()

	var firstContainerIP net.IP
	var containerSubnet *net.IPNet

	if firstContainerIP, containerSubnet, err = net.ParseCIDR(config.Current.ContainerSubnet); err != nil {
		return nil, err
	}

	if vm.IP == nil {
		ipInt := nextCounterValue("vm_ip", int(binary.BigEndian.Uint32(firstContainerIP.To4())))
		ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))

		query := func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}})
		}

		if err := mongodb.Run("jVMs", query); err != nil {
			return nil, err
		}

		vm.IP = ip
	}

	if !containerSubnet.Contains(vm.IP) {
		return nil, fmt.Errorf("VM with IP that is not in the container subnet: %s", vm.IP.String())
	}

	if vm.LdapPassword == "" {
		ldapPassword := utils.RandomString()

		query := func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"ldapPassword": ldapPassword}})
		}

		if err := mongodb.Run("jVMs", query); err != nil {
			return nil, err
		}

		vm.LdapPassword = ldapPassword
	}

	return &vm, nil
}

func getVos(username, hostname string) (*virt.VOS, error) {
	user, err := getUser(username)
	if err != nil {
		return nil, err
	}

	// hostname is used for matching 'hostnameAlias' in jVMs model
	vm, err := getVm(hostname)
	if err != nil {
		return nil, err
	}

	if p := vm.GetPermissions(user); p == nil {
		return nil, fmt.Errorf("user '%s' with uid '%s' doesn't have permission", user.Name, user.Uid)
	}

	return vm.OS(user)
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
