package main

import (
	"koding/kites/os/ldapserver"
	"koding/tools/config"
	"koding/tools/db"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/lifecycle"
	"koding/tools/log"
	"koding/tools/utils"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"sync"
	"time"
)

type VMInfo struct {
	vmId          bson.ObjectId
	sessions      map[*kite.Session]bool
	timeout       *time.Timer
	totalCpuUsage int

	State       string `json:"state"`
	CpuUsage    int    `json:"cpuUsage"`
	CpuShares   int    `json:"cpuShares"`
	MemoryUsage int    `json:"memoryUsage"`
	MemoryLimit int    `json:"memoryLimit"`
}

var infos = make(map[bson.ObjectId]*VMInfo)
var infosMutex sync.Mutex

func main() {
	lifecycle.Startup("kite.os", true)
	virt.LoadTemplates(config.Current.ProjectRoot + "/go/templates")

	iter := db.VMs.Find(bson.M{"ip": bson.M{"$ne": nil}}).Iter()
	var vm virt.VM
	for iter.Next(&vm) {
		switch vm.GetState() {
		case "RUNNING":
			info := newInfo(&vm)
			infos[vm.Id] = info
			info.startTimeout()
		case "STOPPED":
			vm.Unprepare()
		default:
			panic("Unhandled VM state.")
		}
	}
	if iter.Err() != nil {
		panic(iter.Err())
	}

	go ldapserver.Listen()
	go LimiterLoop()
	k := kite.New("os")

	k.Handle("vm.start", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		_, vm := findSession(session)
		return vm.Start()
	})

	k.Handle("vm.shutdown", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		_, vm := findSession(session)
		return vm.Shutdown()
	})

	k.Handle("vm.stop", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		_, vm := findSession(session)
		return vm.Stop()
	})

	k.Handle("vm.info", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		_, vm := findSession(session)
		info := infos[vm.Id]
		info.State = vm.GetState()
		return info, nil
	})

	k.Handle("vm.reinitialize", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		_, vm := findSession(session)
		vm.Prepare(getUsers(vm), true)
		return vm.Start()
	})

	k.Handle("spawn", true, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var command []string
		if args.Unmarshal(&command) != nil {
			return nil, &kite.ArgumentError{Expected: "array of strings"}
		}

		user, vm := findSession(session)
		return vm.AttachCommand(user.Uid, "", command...).CombinedOutput()
	})

	k.Handle("exec", true, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var line string
		if args.Unmarshal(&line) != nil {
			return nil, &kite.ArgumentError{Expected: "string"}
		}

		user, vm := findSession(session)
		return vm.AttachCommand(user.Uid, "", "/bin/bash", "-c", line).CombinedOutput()
	})

	registerFileSystemMethods(k)
	registerWebtermMethods(k)
	registerAppMethods(k)

	k.Run()
}

func findSession(session *kite.Session) (*virt.User, *virt.VM) {
	var user virt.User
	if err := db.Users.Find(bson.M{"username": session.Username}).One(&user); err != nil {
		panic(err)
	}
	if user.Uid < virt.UserIdOffset {
		panic("User with too low uid.")
	}
	vm := getDefaultVM(&user)

	infosMutex.Lock()
	info, isExistingState := infos[vm.Id]
	if !isExistingState {
		info = newInfo(vm)
		infos[vm.Id] = info
	}
	if !info.sessions[session] {
		info.sessions[session] = true
		if info.timeout != nil {
			info.timeout.Stop()
			info.timeout = nil
		}

		session.OnDisconnect(func() {
			infosMutex.Lock()
			defer infosMutex.Unlock()

			delete(info.sessions, session)
			if len(info.sessions) == 0 {
				info.startTimeout()
			}
		})
	}
	infosMutex.Unlock()

	if !isExistingState {
		if vm.IP == nil {
			ipInt := db.NextCounterValue("vm_ip")
			ip := net.IPv4(byte(ipInt>>24), byte(ipInt>>16), byte(ipInt>>8), byte(ipInt))
			if err := db.VMs.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}}); err != nil {
				panic(err)
			}
			vm.IP = ip
		}

		vm.Prepare(getUsers(vm), false)
		if out, err := vm.Start(); err != nil {
			log.Err("Could not start VM.", err, out)
		}
		if out, err := vm.WaitForState("RUNNING", time.Second); err != nil {
			log.Warn("Waiting for VM startup failed.", err, out)
		}
	}

	return &user, vm
}

func getDefaultVM(user *virt.User) *virt.VM {
	if user.DefaultVM == "" {
		// create new vm
		vm := virt.VM{
			Id:           bson.NewObjectId(),
			Name:         user.Name,
			Users:        []*virt.UserEntry{{Id: user.ObjectId, Sudo: true}},
			LdapPassword: utils.RandomString(),
		}
		if err := db.VMs.Insert(vm); err != nil {
			panic(err)
		}

		if err := db.Users.Update(bson.M{"_id": user.ObjectId, "defaultVM": nil}, bson.M{"$set": bson.M{"defaultVM": vm.Id}}); err != nil {
			panic(err)
		}
		user.DefaultVM = vm.Id

		return &vm
	}

	var vm virt.VM
	if err := db.VMs.FindId(user.DefaultVM).One(&vm); err != nil {
		panic(err)
	}
	return &vm
}

func getUsers(vm *virt.VM) []virt.User {
	users := make([]virt.User, len(vm.Users))
	for i, entry := range vm.Users {
		if err := db.Users.FindId(entry.Id).One(&users[i]); err != nil {
			panic(err)
		}
		if users[i].Uid == 0 {
			panic("User with uid 0.")
		}
	}
	return users
}

func newInfo(vm *virt.VM) *VMInfo {
	return &VMInfo{
		vmId:          vm.Id,
		sessions:      make(map[*kite.Session]bool),
		totalCpuUsage: utils.MaxInt,
		CpuShares:     1000,
	}
}

func (info *VMInfo) startTimeout() {
	info.timeout = time.AfterFunc(10*time.Minute, func() {
		infosMutex.Lock()
		defer infosMutex.Unlock()

		if len(info.sessions) != 0 {
			return
		}

		var vm virt.VM
		if err := db.VMs.FindId(info.vmId).One(&vm); err != nil {
			log.Err("Could not find VM for shutdown.", err)
		}
		if out, err := vm.Shutdown(); err != nil {
			log.Err("Could not shutdown VM.", err, out)
		}

		if err := vm.Unprepare(); err != nil {
			log.Warn(err.Error())
		}

		delete(infos, vm.Id)
	})
}
