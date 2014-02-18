package main

import (
	"errors"
	"flag"
	"fmt"
	"koding/kite"
	"koding/kite/dnode"
	"koding/tools/fsutils"
	"log"
	"os"
	"path"
	"sync"

	"github.com/howeyc/fsnotify"
)

var (
	port = flag.String("port", "4002", "port to bind itself")

	// watcher variables
	once               sync.Once
	newPaths, oldPaths = make(chan string), make(chan string)
	watchCallbacks     = make(map[string]func(*fsnotify.FileEvent), 100) // Limit of watching folders
)

func main() {
	flag.Parse()

	options := &kite.Options{
		Kitename:    "fs",
		Version:     "0.0.1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
	}

	k := kite.New(options)

	k.HandleFunc("readDirectory", ReadDirectory)
	k.HandleFunc("createDirectory", CreateDirectory)
	k.HandleFunc("ensureNonexistentPath", EnsureNonexistentPath)
	k.HandleFunc("getInfo", GetInfo)
	k.HandleFunc("glob", Glob)
	k.HandleFunc("readFile", ReadFile)
	k.HandleFunc("remove", Remove)
	k.HandleFunc("rename ", Rename)
	k.HandleFunc("setPermissions", SetPermissions)
	k.HandleFunc("writeFile", WriteFile)

	k.Run()
}

func ReadDirectory(r *kite.Request) (interface{}, error) {
	var params struct {
		Path                string
		OnChange            dnode.Function
		WatchSubdirectories bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		log.Println("params", params)
		return nil, errors.New("{ path: [string], onChange: [function], watchSubdirectories: [bool] }")
	}

	response := make(map[string]interface{})

	if params.OnChange != nil {
		onceBody := func() { startWatcher() }
		go once.Do(onceBody)

		// notify new paths to the watcher
		newPaths <- params.Path

		var eventType string
		var fileEntry *fsutils.FileEntry

		changer := func(ev *fsnotify.FileEvent) {
			if ev.IsCreate() {
				eventType = "added"
				fileEntry, _ = fsutils.GetInfo(ev.Name)
			} else if ev.IsDelete() {
				eventType = "removed"
				fileEntry = fsutils.NewFileEntry(path.Base(ev.Name), ev.Name)
			}

			event := map[string]interface{}{
				"event": eventType,
				"file":  fileEntry,
			}

			params.OnChange(event)
			return
		}

		watchCallbacks[params.Path] = changer

		// this callback is called whenever we receive a 'stopWatching' from the client
		response["stopWatching"] = kite.Callback(func(r *kite.Request) {
			delete(watchCallbacks, params.Path)
			oldPaths <- params.Path
		})
	}

	files, err := fsutils.ReadDirectory(params.Path)
	if err != nil {
		return nil, err
	}

	response["files"] = files
	return response, nil
}

func Glob(r *kite.Request) (interface{}, error) {
	var params struct {
		Pattern string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Pattern == "" {
		return nil, errors.New("{ pattern: [string] }")
	}

	files, err := fsutils.Glob(params.Pattern)
	if err != nil {
		return nil, err
	}

	return files, nil
}

func ReadFile(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	buf, err := fsutils.ReadFile(params.Path)
	if err != nil {
		return nil, err
	}

	result := map[string]interface{}{"content": buf}
	return result, nil
}

func WriteFile(r *kite.Request) (interface{}, error) {
	var params struct {
		Path           string
		Content        []byte
		DoNotOverwrite bool
		Append         bool
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" || params.Content == nil {
		return nil, errors.New("{ path: [string], content: [base64], doNotOverwrite: [bool], append: [bool] }")
	}

	err := fsutils.WriteFile(params.Path, params.Content, params.DoNotOverwrite, params.Append)
	if err != nil {
		return nil, err
	}

	return fmt.Sprintf("content written to %s", params.Path), nil
}

func EnsureNonexistentPath(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	name, err := fsutils.EnsureNonexistentPath(params.Path)
	if err != nil {
		return nil, err
	}

	return name, nil
}

func GetInfo(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	fileEntry, err := fsutils.GetInfo(params.Path)
	if err != nil {
		return nil, err
	}

	return fileEntry, nil
}

func SetPermissions(r *kite.Request) (interface{}, error) {
	var params struct {
		Path      string
		Mode      os.FileMode
		Recursive bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string], mode: [integer], recursive: [bool] }")
	}

	err := fsutils.SetPermissions(params.Path, params.Mode, params.Recursive)
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

	err := fsutils.Remove(params.Path)
	if err != nil {
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

	err := fsutils.Rename(params.OldPath, params.NewPath)
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

	err := fsutils.CreateDirectory(params.Path, params.Recursive)
	if err != nil {
		return nil, err
	}

	return true, nil
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
