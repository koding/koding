package main

import (
	"exp/inotify"
	"koding/tools/dnode"
	"koding/tools/log"
	"os"
	"path"
	"sync"
)

var watcher *inotify.Watcher
var watchMap = make(map[string][]*Watch)
var watchMutex sync.Mutex

type Watch struct {
	Path     string
	Callback dnode.Callback
}

func NewWatch(path string, callback dnode.Callback) (*Watch, error) {
	watchMutex.Lock()
	defer watchMutex.Unlock()

	err := watcher.AddWatch(path, inotify.IN_CREATE|inotify.IN_DELETE|inotify.IN_MODIFY|inotify.IN_MOVE)
	if err != nil {
		return nil, err
	}

	watch := &Watch{path, callback}
	watchMap[path] = append(watchMap[path], watch)
	return watch, nil
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
				fireCallbacks(path.Dir(ev.Name), "added", makeFileEntry(info))
				continue
			}
			if (ev.Mask & (inotify.IN_DELETE | inotify.IN_MOVED_FROM)) != 0 {
				fireCallbacks(path.Dir(ev.Name), "removed", FileEntry{Name: path.Base(ev.Name)})
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

func fireCallbacks(dir, event string, file FileEntry) {
	watchMutex.Lock()
	for _, watch := range watchMap[dir] {
		watch.Callback(map[string]interface{}{"event": event, "file": file})
	}
	watchMutex.Unlock()
}
