package main

import (
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/utils"
	"koding/virt"
	"os"
	"path"
	"sync"
	"syscall"
	"time"
)

type VMState struct {
	sessions         map[*kite.Session]bool
	timeout          *time.Timer
	previousCpuUsage int
	cpuShares        int
}

var states = make(map[string]*VMState)
var statesMutex sync.Mutex

func main() {
	utils.Startup("os kite", true)

	go LimiterLoop()
	k := kite.New("os")

	k.Handle("startVM", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		vm := virt.GetDefaultVM(session.User)
		AddSession(vm, session)
		return vm.StartCommand().CombinedOutput()
	})

	k.Handle("shutdownVM", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		return virt.GetDefaultVM(session.User).ShutdownCommand().CombinedOutput()
	})

	k.Handle("stopVM", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		return virt.GetDefaultVM(session.User).StopCommand().CombinedOutput()
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

	k.Handle("createWebtermServer", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		remote, err := args.Map()
		if err != nil {
			return nil, err
		}
		server := &WebtermServer{session: session}
		server.remote = remote
		session.OnDisconnect(func() { server.Close() })
		return server, nil
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
			sessions:         make(map[*kite.Session]bool),
			previousCpuUsage: utils.MaxInt,
			cpuShares:        1000,
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
		state.timeout = time.AfterFunc(10*time.Minute, func() {
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
