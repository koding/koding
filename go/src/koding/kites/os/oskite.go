package main

import (
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/utils"
	"koding/virt"
	"os"
	"path"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

type VMState struct {
	sessions      map[*kite.Session]bool
	timeout       *time.Timer
	totalCpuUsage int

	CpuUsage    int `json:"cpuUsage"`
	CpuShares   int `json:"cpuShares"`
	MemoryUsage int `json:"memoryUsage"`
	MemoryLimit int `json:"memoryLimit"`
}

var states = make(map[string]*VMState)
var statesMutex sync.Mutex

func main() {
	utils.Startup("kite.os", true)

	go LimiterLoop()
	k := kite.New("os")

	k.Handle("vm.start", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		vm := virt.GetDefaultVM(session.User)
		AddSession(vm, session)
		return vm.StartCommand().CombinedOutput()
	})

	k.Handle("vm.shutdown", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		return virt.GetDefaultVM(session.User).ShutdownCommand().CombinedOutput()
	})

	k.Handle("vm.stop", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		return virt.GetDefaultVM(session.User).StopCommand().CombinedOutput()
	})

	k.Handle("vm.state", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		return states[virt.GetDefaultVM(session.User).String()], nil
	})

	k.Handle("spawn", true, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var command []string
		if args.Unmarshal(&command) != nil {
			return nil, &kite.ArgumentError{"array of strings"}
		}

		return virt.GetDefaultVM(session.User).AttachCommand(session.User.Id, command...).CombinedOutput()
	})

	k.Handle("exec", true, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var line string
		if args.Unmarshal(&line) != nil {
			return nil, &kite.ArgumentError{"string"}
		}

		return virt.GetDefaultVM(session.User).AttachCommand(session.User.Id, "/bin/bash", "-c", line).CombinedOutput()
	})

	k.Handle("watch", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path     string         `json:"path"`
			OnChange dnode.Callback `json:"onChange"`
		}
		if args.Unmarshal(&params) != nil || params.OnChange == nil {
			return nil, &kite.ArgumentError{"{ path: [string], onChange: [function] }"}
		}

		absPath := path.Join(session.Home, params.Path)
		info, err := os.Stat(absPath)
		if err != nil {
			return nil, err
		}
		if int(info.Sys().(*syscall.Stat_t).Uid) != session.User.Id {
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
		dir, err := os.Open("/var/run/screen/S-" + session.User.Name)
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
			return nil, &kite.ArgumentError{"{ remote: [object], name: [string], sizeX: [integer], sizeY: [integer] }"}
		}

		return newWebtermServer(session, params.Remote, []string{"-S", params.Name}, params.SizeX, params.SizeY), nil
	})

	k.Handle("webterm.joinSession", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Remote       WebtermRemote
			SessionId    int
			SizeX, SizeY int
		}
		if args.Unmarshal(&params) != nil || params.SessionId <= 0 || params.SizeX <= 0 || params.SizeY <= 0 {
			return nil, &kite.ArgumentError{"{ remote: [object], sessionId: [integer], sizeX: [integer], sizeY: [integer] }"}
		}

		return newWebtermServer(session, params.Remote, []string{"-x", strconv.Itoa(int(params.SessionId))}, params.SizeX, params.SizeY), nil
	})

	k.Run()
}

func AddSession(vm *virt.VM, session *kite.Session) {
	statesMutex.Lock()
	defer statesMutex.Unlock()

	state, found := states[vm.String()]
	if !found {
		vm.Prepare()
		state = &VMState{
			sessions:      make(map[*kite.Session]bool),
			totalCpuUsage: utils.MaxInt,
			CpuShares:     1000,
		}
		states[vm.String()] = state
	}

	if !state.sessions[session] {
		return
	}
	state.sessions[session] = true
	if state.timeout != nil {
		state.timeout.Stop()
		state.timeout = nil
	}

	session.OnDisconnect(func() {
		statesMutex.Lock()
		defer statesMutex.Unlock()

		delete(state.sessions, session)
		if len(state.sessions) != 0 {
			return
		}
		state.timeout = time.AfterFunc(1*time.Minute, func() {
			statesMutex.Lock()
			defer statesMutex.Unlock()

			if len(state.sessions) != 0 {
				return
			}
			vm.ShutdownCommand().Run()
			vm.Unprepare()
			delete(states, vm.String())
		})
	})
}

type FileEntry struct {
	Name  string `json:"name"`
	IsDir bool   `json:"isDir"`
}

func makeFileEntry(info os.FileInfo) FileEntry {
	return FileEntry{Name: info.Name(), IsDir: info.IsDir()}
}
