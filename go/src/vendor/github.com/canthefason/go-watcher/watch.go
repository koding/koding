// Package watcher watches all file changes via fsnotify package and sends
// update events to builder
package watcher

import (
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	fsnotify "gopkg.in/fsnotify.v1"
)

// GoPath not set error
var ErrPathNotSet = errors.New("gopath not set")

var watchedFileExt = []string{".go", ".tmpl", ".tpl", ".html"}

var watchDelta = 1000 * time.Millisecond

// Watcher watches the file change events from fsnotify and
// sends update messages. It is also used as a fsnotify.Watcher wrapper
type Watcher struct {
	rootdir     string
	watcher     *fsnotify.Watcher
	watchVendor bool
	// when a file gets changed a message is sent to the update channel
	update chan struct{}
}

// MustRegisterWatcher creates a new Watcher and starts listening to
// given folders
func MustRegisterWatcher(params *Params) *Watcher {
	watchVendorStr := params.Get("watch-vendor")
	var watchVendor bool
	var err error
	if watchVendorStr != "" {
		watchVendor, err = strconv.ParseBool(watchVendorStr)
		if err != nil {
			log.Println("Wrong watch-vendor value: %s (default=false)", watchVendorStr)
		}
	}

	w := &Watcher{
		update:      make(chan struct{}),
		rootdir:     params.Get("watch"),
		watchVendor: watchVendor,
	}

	w.watcher, err = fsnotify.NewWatcher()
	if err != nil {
		log.Fatalf("Could not register watcher: %s", err)
	}

	// add folders that will be watched
	w.watchFolders()

	return w
}

// Watch listens file updates, and sends signal to
// update channel when .go and .tmpl files are updated
func (w *Watcher) Watch() {
	eventSent := false

	for {
		select {
		case event := <-w.watcher.Events:
			// discard chmod events
			if event.Op&fsnotify.Chmod != fsnotify.Chmod {
				// test files do not need a rebuild
				if isTestFile(event.Name) {
					continue
				}
				if !isWatchedFileType(event.Name) {
					continue
				}
				if eventSent {
					continue
				}
				eventSent = true
				// prevent consequent builds
				go func() {
					w.update <- struct{}{}
					time.Sleep(watchDelta)
					eventSent = false
				}()

			}
		case err := <-w.watcher.Errors:
			if err != nil {
				log.Fatalf("Watcher error: %s", err)
			}
			return
		}
	}
}

func isTestFile(fileName string) bool {
	return strings.HasSuffix(filepath.Base(fileName), "_test.go")
}

func isWatchedFileType(fileName string) bool {
	ext := filepath.Ext(fileName)

	return existIn(ext, watchedFileExt)
}

// Wait waits for the latest messages
func (w *Watcher) Wait() <-chan struct{} {
	return w.update
}

// Close closes the fsnotify watcher channel
func (w *Watcher) Close() {
	w.watcher.Close()
	close(w.update)
}

// watchFolders recursively adds folders that will be watched against the changes,
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

		if !w.watchVendor {
			// skip vendor directory
			vendor := fmt.Sprintf("%s/vendor", wd)
			if strings.HasPrefix(path, vendor) {
				return filepath.SkipDir
			}
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
