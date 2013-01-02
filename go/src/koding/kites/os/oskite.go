package main

import (
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/utils"
	"os"
	"path"
	"syscall"
)

func main() {
	utils.Startup("os kite", true)

	k := kite.New("os")

	k.Handle("spawn", true, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var command []string
		if args.Unmarshal(&command) != nil {
			return nil, &kite.ArgumentError{"array of strings"}
		}

		output, err := session.CreateCommand(command...).CombinedOutput()
		return string(output), err
	})

	k.Handle("exec", true, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var line string
		if args.Unmarshal(&line) != nil {
			return nil, &kite.ArgumentError{"string"}
		}

		output, err := session.CreateCommand("/bin/bash", "-c", line).CombinedOutput()
		return string(output), err
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
		if int(info.Sys().(*syscall.Stat_t).Uid) != session.Uid {
			return nil, fmt.Errorf("You can only watch your own directories.")
		}

		watch, err := NewWatch(absPath, params.OnChange)
		if err != nil {
			return nil, err
		}
		session.CloseOnDisconnect(watch)

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
		session.CloseOnDisconnect(server)
		return server, nil
	})

	k.Run()
}

type FileEntry struct {
	Name  string `json:"name"`
	IsDir bool   `json:"isDir"`
}

func makeFileEntry(info os.FileInfo) FileEntry {
	return FileEntry{Name: info.Name(), IsDir: info.IsDir()}
}
