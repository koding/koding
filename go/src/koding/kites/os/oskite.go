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

	kite.Run("os", func(session *kite.Session, method string, args interface{}) (interface{}, error) {
		switch method {
		case "spawn":
			array, ok := args.([]interface{})
			if !ok {
				return nil, &kite.ArgumentError{"array of strings"}
			}
			command := make([]string, len(array))
			for i, entry := range array {
				command[i], ok = entry.(string)
				if !ok {
					return nil, &kite.ArgumentError{"array of strings"}
				}
			}
			return run(command, session)

		case "exec":
			line, ok := args.(string)
			if !ok {
				return nil, &kite.ArgumentError{"string"}
			}
			return run([]string{"/bin/bash", "-c", line}, session)

		case "watch":
			argMap, ok1 := args.(map[string]interface{})
			relPath, ok2 := argMap["path"].(string)
			onChange, ok3 := argMap["onChange"].(dnode.Callback)
			if !ok1 || !ok2 || !ok3 {
				return nil, &kite.ArgumentError{"{ path: [string], onChange: [function] }"}
			}

			absPath := path.Join(session.Home, relPath)
			info, err := os.Stat(absPath)
			if err != nil {
				return nil, err
			}
			if int(info.Sys().(*syscall.Stat_t).Uid) != session.Uid {
				return nil, fmt.Errorf("You can only watch your own directories.")
			}

			watch, err := NewWatch(absPath, onChange)
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
		}

		return nil, &kite.UnknownMethodError{method}
	})
}

type FileEntry struct {
	Name  string `json:"name"`
	IsDir bool   `json:"isDir"`
}

func makeFileEntry(info os.FileInfo) FileEntry {
	return FileEntry{Name: info.Name(), IsDir: info.IsDir()}
}

func run(command []string, session *kite.Session) (string, error) {
	cmd := session.CreateCommand(command)
	output, err := cmd.CombinedOutput()
	return string(output), err
}
