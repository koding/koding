package main

import (
	"exp/inotify"
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/log"
	"koding/tools/utils"
	"os"
	"path"
	"strings"
)

func main() {
	utils.DefaultStartup("os kite", true)

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

			absPath := path.Clean(path.Join(session.Home, relPath))
			if !path.IsAbs(absPath) || !strings.HasPrefix(absPath, session.Home) {
				return nil, fmt.Errorf("Can only watch inside of home directory.")
			}

			watcher, err := inotify.NewWatcher()
			if err != nil {
				return nil, err
			}
			session.CloseOnDisconnect = append(session.CloseOnDisconnect, watcher)
			watcher.AddWatch(absPath, inotify.IN_CREATE|inotify.IN_DELETE|inotify.IN_MODIFY)
			go func() {
				for ev := range watcher.Event {
					if (ev.Mask & (inotify.IN_CREATE | inotify.IN_MODIFY)) != 0 {
						info, err := os.Stat(ev.Name)
						if err != nil {
							log.Warn("Watcher error", err)
						} else if (ev.Mask & inotify.IN_CREATE) != 0 {
							onChange(map[string]interface{}{"event": "create", "file": makeFileEntry(info)})
						} else {
							onChange(map[string]interface{}{"event": "modify", "file": makeFileEntry(info)})
						}
					} else if (ev.Mask & inotify.IN_DELETE) != 0 {
						onChange(map[string]interface{}{"event": "delete", "file": FileEntry{Name: path.Base(ev.Name)}})
					} else {
						log.Warn("Watcher error", ev.Mask)
					}
				}
			}()
			go func() {
				for err := range watcher.Error {
					log.Warn("Watcher error", err)
				}
			}()

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

			return map[string]interface{}{"files": entries, "stopWatching": func() { watcher.Close() }}, nil
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
