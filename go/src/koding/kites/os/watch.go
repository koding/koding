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
			var event string
			var file FileEntry
			if (ev.Mask & (inotify.IN_CREATE | inotify.IN_MODIFY | inotify.IN_MOVED_TO)) != 0 {
				event = "added"
				info, err := os.Lstat(ev.Name)
				if err != nil {
					log.Warn("Watcher error", err)
					continue
				}
				file = makeFileEntry(info)
			} else if (ev.Mask & (inotify.IN_DELETE | inotify.IN_MOVED_FROM)) != 0 {
				event = "removed"
				file = FileEntry{Name: path.Base(ev.Name)}
			} else {
				continue
			}
			watchMutex.Lock()
			for _, watch := range watchMap[path.Dir(ev.Name)] {
				watch.Callback(map[string]interface{}{"event": event, "file": file})
			}
			watchMutex.Unlock()
		}
	}()
	go func() {
		for err := range watcher.Error {
			log.Warn("Watcher error", err)
		}
	}()
}
