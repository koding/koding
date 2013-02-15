package main

import (
	"fmt"
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
	"os"
	"path"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

type VMState struct {
	vmId          bson.ObjectId
	sessions      map[*kite.Session]bool
	timeout       *time.Timer
	totalCpuUsage int

	CpuUsage    int `json:"cpuUsage"`
	CpuShares   int `json:"cpuShares"`
	MemoryUsage int `json:"memoryUsage"`
	MemoryLimit int `json:"memoryLimit"`
}

var ipPoolFetch <-chan int
var ipPoolRelease chan<- int
var states = make(map[bson.ObjectId]*VMState)
var statesMutex sync.Mutex

func main() {
	lifecycle.Startup("kite.os", true)
	virt.LoadTemplates(config.Current.ProjectRoot + "/go/templates")

	takenIPs := make([]int, 0)
	iter := db.VMs.Find(bson.M{"ip": bson.M{"$ne": nil}}).Iter()
	var vm virt.VM
	for iter.Next(&vm) {
		switch vm.GetState() {
		case "RUNNING":
			state := newState(&vm)
			states[vm.Id] = state
			state.startTimeout()
			takenIPs = append(takenIPs, utils.IPToInt(vm.IP))
		case "STOPPED":
			vm.Unprepare()
			db.VMs.UpdateId(vm.Id, bson.M{"$set": bson.M{"ip": nil}})
		default:
			panic("Unhandled VM state.")
		}
	}
	if iter.Err() != nil {
		panic(iter.Err())
	}
	ipPoolFetch, ipPoolRelease = utils.NewIntPool(utils.IPToInt(net.IPv4(172, 16, 0, 2)), takenIPs)

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

	k.Handle("vm.state", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		_, vm := findSession(session)
		return states[vm.Id], nil
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

	k.Handle("watch", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path     string         `json:"path"`
			OnChange dnode.Callback `json:"onChange"`
		}
		if args.Unmarshal(&params) != nil || params.OnChange == nil {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], onChange: [function] }"}
		}

		user, _ := findSession(session)
		absPath := path.Join("/home", user.Name, params.Path)
		info, err := os.Stat(absPath)
		if err != nil {
			return nil, err
		}
		if int(info.Sys().(*syscall.Stat_t).Uid) != user.Uid {
			return nil, fmt.Errorf("You can only watch your own directories.")
		}

		watch, err := NewWatch(absPath, params.OnChange)
		if err != nil {
			return nil, err
		}
		session.OnDisconnect(func() { watch.Close() })

		dir, err := os.Open(absPath)
		defer dir.Close()
		if err != nil {
			return nil, err
		}

		infos, err := dir.Readdir(0)
		if err != nil {
			return nil, err
		}

		entries := make([]FileEntry, len(infos))
		for i, info := range infos {
			entries[i] = makeFileEntry(info)
		}

		return map[string]interface{}{"files": entries, "stopWatching": func() { watch.Close() }}, nil
	})

	k.Handle("webterm.getSessions", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		user, _ := findSession(session)
		dir, err := os.Open("/var/run/screen/S-" + user.Name)
		if err != nil {
			if os.IsNotExist(err) {
				return make(map[string]string), nil
			}
			panic(err)
		}
		names, err := dir.Readdirnames(0)
		if err != nil {
			panic(err)
		}
		sessions := make(map[string]string)
		for _, name := range names {
			parts := strings.SplitN(name, ".", 2)
			sessions[parts[0]] = parts[1]
		}
		return sessions, nil
	})

	k.Handle("webterm.createSession", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Remote       WebtermRemote
			Name         string
			SizeX, SizeY int
		}
		if args.Unmarshal(&params) != nil || params.Name == "" || params.SizeX <= 0 || params.SizeY <= 0 {
			return nil, &kite.ArgumentError{Expected: "{ remote: [object], name: [string], sizeX: [integer], sizeY: [integer] }"}
		}

		user, vm := findSession(session)
		server := newWebtermServer(vm, user, params.Remote, []string{"-S", params.Name}, params.SizeX, params.SizeY)
		session.OnDisconnect(func() { server.Close() })
		return server, nil
	})

	k.Handle("webterm.joinSession", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Remote       WebtermRemote
			SessionId    int
			SizeX, SizeY int
		}
		if args.Unmarshal(&params) != nil || params.SessionId <= 0 || params.SizeX <= 0 || params.SizeY <= 0 {
			return nil, &kite.ArgumentError{Expected: "{ remote: [object], sessionId: [integer], sizeX: [integer], sizeY: [integer] }"}
		}

		user, vm := findSession(session)
		server := newWebtermServer(vm, user, params.Remote, []string{"-x", strconv.Itoa(int(params.SessionId))}, params.SizeX, params.SizeY)
		session.OnDisconnect(func() { server.Close() })
		return server, nil
	})

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

	statesMutex.Lock()
	state, isExistingState := states[vm.Id]
	if !isExistingState {
		state = newState(vm)
		states[vm.Id] = state
	}
	if !state.sessions[session] {
		state.sessions[session] = true
		if state.timeout != nil {
			state.timeout.Stop()
			state.timeout = nil
		}

		session.OnDisconnect(func() {
			statesMutex.Lock()
			defer statesMutex.Unlock()

			delete(state.sessions, session)
			if len(state.sessions) == 0 {
				state.startTimeout()
			}
		})
	}
	statesMutex.Unlock()

	if !isExistingState {
		ip := utils.IntToIP(<-ipPoolFetch)
		if err := db.VMs.Update(bson.M{"_id": vm.Id, "ip": nil}, bson.M{"$set": bson.M{"ip": ip}}); err != nil {
			panic(err)
		}
		vm.IP = ip

		users := make([]virt.User, len(vm.Users))
		for i, entry := range vm.Users {
			if err := db.Users.FindId(entry.Id).One(&users[i]); err != nil {
				panic(err)
			}
			if users[i].Uid == 0 {
				panic("User with uid 0.")
			}
		}
		vm.Prepare(users)

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

func newState(vm *virt.VM) *VMState {
	return &VMState{
		vmId:          vm.Id,
		sessions:      make(map[*kite.Session]bool),
		totalCpuUsage: utils.MaxInt,
		CpuShares:     1000,
	}
}

func (state *VMState) startTimeout() {
	state.timeout = time.AfterFunc(10*time.Minute, func() {
		statesMutex.Lock()
		defer statesMutex.Unlock()

		if len(state.sessions) != 0 {
			return
		}

		var vm virt.VM
		if err := db.VMs.FindId(state.vmId).One(&vm); err != nil {
			log.Err("Could not find VM for shutdown.", err)
		}
		if out, err := vm.Shutdown(); err != nil {
			log.Err("Could not shutdown VM.", err, out)
		}

		if err := vm.Unprepare(); err != nil {
			log.Warn(err.Error())
		}
		db.VMs.UpdateId(vm.Id, bson.M{"$set": bson.M{"ip": nil}})
		ipPoolRelease <- utils.IPToInt(vm.IP)
		vm.IP = nil

		delete(states, vm.Id)
	})
}

type FileEntry struct {
	Name  string `json:"name"`
	IsDir bool   `json:"isDir"`
}

func makeFileEntry(info os.FileInfo) FileEntry {
	return FileEntry{Name: info.Name(), IsDir: info.IsDir()}
}
