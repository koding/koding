package main

import (
	"exp/inotify"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/log"
	"koding/virt"
	"os"
	"path"
	"sync"
	"time"
)

var watcher *inotify.Watcher
var watchMap = make(map[string][]*Watch)
var watchMutex sync.Mutex

type Watch struct {
	VM       *virt.VM
	User     *virt.User
	Path     string
	Callback dnode.Callback
}

type FileEntry struct {
	Name     string      `json:"name"`
	IsDir    bool        `json:"isDir"`
	Size     int64       `json:"size"`
	Mode     os.FileMode `json:"mode"`
	Time     time.Time   `json:"time"`
	IsBroken bool        `json:"isBroken"`
}

func init() {
	var err error
	watcher, err = inotify.NewWatcher()
	if err != nil {
		panic(err)
	}

	go func() {
		for ev := range watcher.Event {
			if (ev.Mask & (inotify.IN_CREATE | inotify.IN_MODIFY | inotify.IN_MOVED_TO)) != 0 {
				info, err := os.Lstat(ev.Name)
				if err != nil {
					log.Warn("Watcher error", err)
					continue
				}
				watchMutex.Lock()
				for _, watch := range watchMap[path.Dir(ev.Name)] {
					watch.Callback(map[string]interface{}{
						"event": "added",
						"file":  watch.makeFileEntry(info),
					})
				}
				watchMutex.Unlock()
				continue
			}
			if (ev.Mask & (inotify.IN_DELETE | inotify.IN_MOVED_FROM)) != 0 {
				watchMutex.Lock()
				for _, watch := range watchMap[path.Dir(ev.Name)] {
					watch.Callback(map[string]interface{}{
						"event": "removed",
						"file":  FileEntry{Name: path.Base(ev.Name)},
					})
				}
				watchMutex.Unlock()
				continue
			}
		}
	}()
	go func() {
		for err := range watcher.Error {
			log.Warn("Watcher error", err)
		}
	}()
}

func WatchDir(vm *virt.VM, user *virt.User, vmPath string, callback dnode.Callback, session *kite.Session) (interface{}, error) {
	watchMutex.Lock()
	defer watchMutex.Unlock()

	if !path.IsAbs(vmPath) {
		vmPath = "/home/" + user.Name + "/" + vmPath
	}
	fullPath, err := vm.ResolveRootfsFile(vmPath, user)
	if err != nil {
		return nil, err
	}

	err = watcher.AddWatch(fullPath, inotify.IN_CREATE|inotify.IN_DELETE|inotify.IN_MODIFY|inotify.IN_MOVE)
	if err != nil {
		return nil, err
	}

	watch := &Watch{vm, user, vmPath, callback}
	watchMap[fullPath] = append(watchMap[fullPath], watch)
	session.OnDisconnect(func() { watch.Close() })

	dir, err := os.Open(fullPath)
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
		entries[i] = watch.makeFileEntry(info)
	}

	return map[string]interface{}{"files": entries, "stopWatching": func() { watch.Close() }}, nil
}

func (watch *Watch) Close() error {
	watchMutex.Lock()
	defer watchMutex.Unlock()

	watches := watchMap[watch.Path]
	for i, w := range watches {
		if w == watch {
			watches[i] = watches[len(watches)-1]
			watches = watches[:len(watches)-1]
			break
		}
	}
	watchMap[watch.Path] = watches

	if len(watches) == 0 {
		watcher.RemoveWatch(watch.Path)
	}

	return nil
}

func (watch *Watch) makeFileEntry(info os.FileInfo) FileEntry {
	entry := FileEntry{
		Name:  info.Name(),
		IsDir: info.IsDir(),
		Size:  info.Size(),
		Mode:  info.Mode(),
		Time:  info.ModTime(),
	}

	if info.Mode()&os.ModeSymlink != 0 {
		fullPath, err := watch.VM.ResolveRootfsFile(watch.Path+"/"+info.Name(), watch.User)
		if err != nil {
			entry.IsBroken = true
			return entry
		}
		symlinkInfo, err := os.Lstat(fullPath)
		if err != nil {
			entry.IsBroken = true
			return entry
		}
		entry.IsDir = symlinkInfo.IsDir()
		entry.Size = symlinkInfo.Size()
		entry.Mode = symlinkInfo.Mode()
		entry.Time = symlinkInfo.ModTime()
	}

	return entry
}
