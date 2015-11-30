package fuseklient

import (
	"fmt"
	"strings"
	"time"

	"github.com/koding/fuseklient/transport"
)

// WatchInterval is the default interval to watch for changes on remote.
var WatchInterval = 1 * time.Second

type Watcher interface {
	Watch() (<-chan string, <-chan error)
}

type FindWatcher struct {
	// Transport is used for two way communication with user VM.
	transport.Transport

	// RemotePath is full path on user VM.
	RemotePath string

	LastRan time.Time

	WatchInterval time.Duration
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

			for _, s := range entries {
				resChan <- s
			}
		}
	}()

	return resChan, errChan
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
		// TODO: how to remove '/' at end of find results cmd
		splitStrs[i] = strings.TrimPrefix(s, f.RemotePath+"/")
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
