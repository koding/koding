// Package fs provides file system handleFuncs that can be used with kite
// library
package fs

import (
	"errors"
	"log"
	"os"
	"path"
	"sync"

	"github.com/howeyc/fsnotify"
	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

var (
	// watcher variables
	once               sync.Once
	newPaths, oldPaths = make(chan string), make(chan string)

	// Limit of watching folders
	watchCallbacks = make(map[string]func(*fsnotify.FileEvent), 100)
	mu             sync.Mutex // protects watchCallbacks
)

func ReadDirectory(r *kite.Request) (interface{}, error) {
	var params struct {
		Path     string
		OnChange dnode.Function
	}

	if r.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		log.Println("params", params)
		return nil, errors.New("{ path: [string], onChange: [function]}")
	}

	response := make(map[string]interface{})

	if params.OnChange.IsValid() {
		onceBody := func() { startWatcher() }
		go once.Do(onceBody)

		// notify new paths to the watcher
		newPaths <- params.Path

		var eventType string
		var fileEntry *FileEntry

		changer := func(ev *fsnotify.FileEvent) {
			if ev.IsCreate() {
				eventType = "added"
				fileEntry, _ = getInfo(ev.Name)
			} else if ev.IsDelete() {
				eventType = "removed"
				fileEntry = NewFileEntry(path.Base(ev.Name), ev.Name)
			}

			event := map[string]interface{}{
				"event": eventType,
				"file":  fileEntry,
			}

			params.OnChange.Call(event)
			return
		}

		mu.Lock()
		watchCallbacks[params.Path] = changer
		mu.Unlock()

		removePath := func() {
			mu.Lock()
			delete(watchCallbacks, params.Path)
			mu.Unlock()

			oldPaths <- params.Path
		}

		// remove the path when the remote client disconnects
		r.Client.OnDisconnect(removePath)

		// this callback is called whenever we receive a 'stopWatching' from the client
		response["stopWatching"] = dnode.Callback(func(r *dnode.Partial) {
			removePath()
		})
	}

	files, err := readDirectory(params.Path)
	if err != nil {
		return nil, err
	}

	response["files"] = files
	return response, nil
}

func startWatcher() {
	var err error
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}

	go func() {
		for {
			select {
			case p := <-newPaths:
				err := watcher.Watch(p)
				if err != nil {
					log.Println("watch path adding", err)
				}
			case p := <-oldPaths:
				err := watcher.RemoveWatch(p)
				if err != nil {
					log.Println("watch remove adding", err)
				}
			}
		}
	}()

	for event := range watcher.Event {
		mu.Lock()
		f, ok := watchCallbacks[path.Dir(event.Name)]
		mu.Unlock()

		if !ok {
			continue
		}

		f(event)
	}
}

func Glob(r *kite.Request) (interface{}, error) {
	var params struct {
		Pattern string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Pattern == "" {
		return nil, errors.New("{ pattern: [string] }")
	}

	return glob(params.Pattern)
}

func ReadFile(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	return readFile(params.Path)
}

type writeFileParams struct {
	Path           string
	Content        []byte
	DoNotOverwrite bool
	Append         bool
}

func WriteFile(r *kite.Request) (interface{}, error) {
	var params writeFileParams
	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	return writeFile(params.Path, params.Content, params.DoNotOverwrite, params.Append)
}

func UniquePath(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	return uniquePath(params.Path)
}

func GetInfo(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	return getInfo(params.Path)
}

type setPermissionsParams struct {
	Path      string
	Mode      os.FileMode
	Recursive bool
}

func SetPermissions(r *kite.Request) (interface{}, error) {
	var params setPermissionsParams

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string], mode: [integer], recursive: [bool] }")
	}

	err := setPermissions(params.Path, params.Mode, params.Recursive)
	if err != nil {
		return nil, err
	}

	return true, nil
}

func Remove(r *kite.Request) (interface{}, error) {
	var params struct {
		Path      string
		Recursive bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string], recursive: [bool] }")
	}

	if err := remove(params.Path, params.Recursive); err != nil {
		return nil, err
	}

	return true, nil
}

func Rename(r *kite.Request) (interface{}, error) {
	var params struct {
		OldPath string
		NewPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return nil, errors.New("{ oldPath: [string], newPath: [string] }")
	}

	err := rename(params.OldPath, params.NewPath)
	if err != nil {
		return nil, err
	}

	return true, nil
}

func CreateDirectory(r *kite.Request) (interface{}, error) {
	var params struct {
		Path      string
		Recursive bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string], recursive: [bool] }")
	}

	err := createDirectory(params.Path, params.Recursive)
	if err != nil {
		return nil, err
	}

	return true, nil
}

func Move(r *kite.Request) (interface{}, error) {
	var params struct {
		OldPath string
		NewPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return nil, errors.New("{ oldPath: [string], newPath: [string] }")
	}

	err := rename(params.OldPath, params.NewPath)
	if err != nil {
		return nil, err
	}

	return true, nil
}

func Copy(r *kite.Request) (interface{}, error) {
	var params struct {
		SrcPath string
		DstPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.SrcPath == "" || params.DstPath == "" {
		return nil, errors.New("{ srcPath: [string], dstPath: [string] }")
	}

	err := cp(params.SrcPath, params.DstPath)
	if err != nil {
		return nil, err
	}

	return true, nil
}
