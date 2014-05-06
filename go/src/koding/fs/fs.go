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

const (
	FS_NAME    = "fs"
	FS_VERSION = "0.0.1"
)

var (
	// watcher variables
	once               sync.Once
	newPaths, oldPaths = make(chan string), make(chan string)
	watchCallbacks     = make(map[string]func(*fsnotify.FileEvent), 100) // Limit of watching folders
)

func ReadDirectory(r *kite.Request) (interface{}, error) {
	var params struct {
		Path     string
		OnChange dnode.Function
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
				fileEntry = newFileEntry(path.Base(ev.Name), ev.Name)
			}

			event := map[string]interface{}{
				"event": eventType,
				"file":  fileEntry,
			}

			params.OnChange.Call(event)
			return
		}

		watchCallbacks[params.Path] = changer

		// TODO: handle them together
		r.Client.OnDisconnect(func() {
			delete(watchCallbacks, params.Path)
			oldPaths <- params.Path
		})

		// this callback is called whenever we receive a 'stopWatching' from the client
		response["stopWatching"] = dnode.Callback(func(r *dnode.Partial) {
			delete(watchCallbacks, params.Path)
			oldPaths <- params.Path
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
		f, ok := watchCallbacks[path.Dir(event.Name)]
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
		return nil, &kite.ArgumentError{Expected: "{ pattern: [string] }"}
	}

	return glob(params.Pattern)
}

func ReadFile(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return readFile(params.Path, vos)
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
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return writeFile(params.Path, params.Content, params.DoNotOverwrite, params.Append)
}

func UniquePath(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return uniquePath(params.Path)
}

func GetInfo(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
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
		return nil, &kite.ArgumentError{Expected: "{ path: [string], mode: [integer], recursive: [bool] }"}
	}

	return setPermissions(params.Path, params.Mode, params.Recursive)
}

func Remove(r *kite.Request) (interface{}, error) {
	var params struct {
		Path      string
		Recursive bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
	}

	return remove(params.Path, params.Recursive)
}

func Rename(r *kite.Request) (interface{}, error) {
	var params struct {
		OldPath string
		NewPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ oldPath: [string], newPath: [string] }"}
	}

	return rename(params.OldPath, params.NewPath)
}

func CreateDirectory(r *kite.Request) (interface{}, error) {
	var params struct {
		Path      string
		Recursive bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
	}

	return createDirectory(params.Path, params.Recursive)
}

func Move(r *kite.Request) (interface{}, error) {
	var params struct {
		OldPath string
		NewPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ oldPath: [string], newPath: [string] }"}
	}

	return rename(params.OldPath, params.NewPath)
}

func Copy(r *kite.Request) (interface{}, error) {
	var params struct {
		SrcPath string
		DstPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.SrcPath == "" || params.DstPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ srcPath: [string], dstPath: [string] }"}
	}

	return cp(params.SrcPath, params.DstPath)
}
