package fuseklient

import (
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/koding/fuseklient/transport"
)

// WatchInterval is the default interval to watch for changes on remote.
var WatchInterval = 1 * time.Second

type Watcher interface {
	Watch() (<-chan string, <-chan error)
	AddTimedIgnore(string, time.Duration)
}

type FindWatcher struct {
	// Transport is used for two way communication with user VM.
	transport.Transport

	// RemotePath is full path on user VM.
	RemotePath string

	LastRan time.Time

	WatchInterval time.Duration

	sync.Mutex

	ignoredPaths map[string]time.Time
}

func (f *FindWatcher) AddTimedIgnore(path string, duration time.Duration) {
	f.Lock()
	path = trimPrefix(path, f.RemotePath)
	f.ignoredPaths[path] = time.Now().UTC().Add(duration)
	f.Unlock()
}

func (f *FindWatcher) RemoveTimedIgnore(path string) {
	f.Lock()
	path = trimPrefix(path, f.RemotePath)
	delete(f.ignoredPaths, path)
	f.Unlock()
}

func (f *FindWatcher) Watch() (<-chan string, <-chan error) {
	resChan := make(chan string)
	errChan := make(chan error)

	go func() {
		ticker := time.Tick(1 * time.Second)
		for _ = range ticker {
			f.LastRan = time.Now().UTC()

			entries, err := f.getChangedFiles()
			if err != nil {
				errChan <- err
				continue
			}

			for _, e := range entries {
				if !f.isPathIgnored(e) {
					resChan <- e
				}
			}
		}
	}()

	return resChan, errChan
}

func (f *FindWatcher) isPathIgnored(path string) bool {
	expiration, ok := f.ignoredPaths[path]
	if !ok {
		return false
	}

	if expiration.After(time.Now().UTC()) {
		return true
	}

	// remove expired entries from list of paths
	delete(f.ignoredPaths, path)

	return false
}

func (f *FindWatcher) getChangedFiles() ([]string, error) {
	min := time.Now().Sub(f.LastRan).Minutes()
	if min < 1 {
		min = 1
	}
	cmd := fmt.Sprintf("find %s -mmin -%v", f.RemotePath, min)

	req := struct{ Command string }{cmd}
	var res struct {
		Stdout     string `json:"stdout"`
		Stderr     string `json:"stderr"`
		ExitStatus int    `json:"exitStatus"`
	}

	if err := f.Trip("exec", req, &res); err != nil {
		return nil, err
	}

	if res.ExitStatus != 0 {
		return nil, fmt.Errorf("exit status is not 0, err: %s", res.Stderr)
	}

	splitStrs := strings.Split(res.Stdout, "\n")
	for i, s := range splitStrs {
		splitStrs[i] = trimPrefix(s, f.RemotePath)
	}

	return splitStrs, nil
}

// NewFindWatcher asks remote for changes in entries by running `find` command
// on remote.
func NewFindWatcher(t transport.Transport, r string) *FindWatcher {
	return &FindWatcher{
		Transport:     t,
		RemotePath:    r,
		WatchInterval: WatchInterval,
		ignoredPaths:  map[string]time.Time{},
	}
}

// Watch is used to keep local synced with remote. It accepts a channel to
// listen for file or folder changes; when an item is sent to channel, it
// searches for the item in the specified Dir and invalidates the item's
// cache. If item is not matched, it simply ignores it.
//
// This is blocking operation and should be run in a goroutine.
func WatchForRemoteChanges(dir *Dir, watcher Watcher) error {
	changes, errs := watcher.Watch()

	for {
		select {
		case item := <-changes:
			if item = strings.TrimSpace(item); item == "" {
				continue
			}

			if item, err := dir.findEntryRecursive(item); err == nil {
				if item != nil {
					item.Expire()
				}
			}
		case err := <-errs:
			return err
		}
	}

	return nil
}

// TODO: how to remove '/' at end of find results cmd
func trimPrefix(p, remotePath string) string {
	return strings.TrimPrefix(p, remotePath+"/")
}
