// Package watcher watches all file changes via fsnotify package and sends
// update events to builder
package watcher

import (
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	fsnotify "gopkg.in/fsnotify.v1"
)

// Watcher watches the file change events from fsnotify and
// sends update messages. It is also used as a fsnotify.Watcher wrapper
type Watcher struct {
	rootdir string
	watcher *fsnotify.Watcher
	// when file is changed a message is sent to update channel
	update chan bool
}

// GoPath not set error
var ErrPathNotSet = errors.New("gopath not set")

// MustRegisterWatcher creates a new Watcher and starts listening
// given folders
func MustRegisterWatcher(params *Params) *Watcher {

	w := &Watcher{
		update:  make(chan bool),
		rootdir: params.Get("watch"),
	}

	var err error
	w.watcher, err = fsnotify.NewWatcher()
	if err != nil {
		log.Fatalf("Could not register watcher: %s", err)
	}

	// add watched paths
	w.watchFolders()

	return w
}

// Watch listens file updates, and sends signal to
// update channel when go files are updated
func (w *Watcher) Watch() {
	eventSent := false

	for {
		select {
		case event := <-w.watcher.Events:
			// discard chmod events
			if event.Op&fsnotify.Chmod != fsnotify.Chmod {
				ext := filepath.Ext(event.Name)
				if ext == ".go" || ext == ".tmpl" {
					if !eventSent {

						// prevent consequent build
						eventSent = true
						go func() {
							time.Sleep(200 * time.Millisecond)
							eventSent = false
						}()
						w.update <- true
					}
				}

			}
		case err := <-w.watcher.Errors:
			if err != nil {
				log.Fatalf("Watcher error: %s", err)
			}
			return
		}
	}
}

func (w *Watcher) Wait() <-chan bool {
	return w.update
}

// Close closes the fsnotify watcher channel
func (w *Watcher) Close() {
	w.watcher.Close()
	// close(w.update)
}

// watchFolders recursively adds folders that will be watched for changes,
// starting from the working directory
func (w *Watcher) watchFolders() {
	wd, err := w.prepareRootDir()

	if err != nil {
		log.Fatalf("Could not get root working directory: %s", err)
	}

	filepath.Walk(wd, func(path string, info os.FileInfo, err error) error {
		// skip files
		if info == nil {
			log.Fatalf("wrong watcher package: %s", path)
		}

		if !info.IsDir() {
			return nil
		}

		// skip hidden folders
		if len(path) > 1 && strings.HasPrefix(filepath.Base(path), ".") {
			return filepath.SkipDir
		}

		w.addFolder(path)

		return err
	})
}

// addFolder adds given folder name to the watched folders, and starts
// watching it for further changes
func (w *Watcher) addFolder(name string) {
	if err := w.watcher.Add(name); err != nil {
		log.Fatalf("Could not watch folder: %s", err)
	}
}

// prepareRootDir prepares working directory depending on root directory
func (w *Watcher) prepareRootDir() (string, error) {
	if w.rootdir == "" {
		return os.Getwd()
	}

	path := os.Getenv("GOPATH")
	if path == "" {
		return "", ErrPathNotSet
	}

	root := fmt.Sprintf("%s/src/%s", path, w.rootdir)

	return root, nil
}
