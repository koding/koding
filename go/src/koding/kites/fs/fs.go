package main

import (
	"errors"
	"flag"
	"fmt"
	"github.com/howeyc/fsnotify"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/tools/dnode"
	"koding/tools/fsutils"
	"log"
	"os"
	"path"
	"sync"
)

type Fs struct{}

var (
	port = flag.String("port", "4002", "port to bind itself")

	// watcher variables
	once               sync.Once
	newPaths, oldPaths = make(chan string), make(chan string)
	watchCallbacks     = make(map[string]func(*fsnotify.FileEvent), 100) // Limit of watching folders
)

func main() {
	flag.Parse()
	options := &protocol.Options{
		PublicIP: "localhost",
		Kitename: "fs",
		Version:  "1",
		Port:     *port,
	}

	methods := map[string]string{
		"fs.createDirectory":       "ReadDirectory",
		"fs.ensureNonexistentPath": "EnsureNonexistentPath",
		"fs.getInfo":               "GetInfo",
		"fs.glob":                  "Glob",
		"fs.readDirectory":         "ReadDirectory",
		"fs.readFile":              "ReadFile",
		"fs.remove":                "Remove",
		"fs.rename ":               "Rename",
		"fs.setPermissions":        "SetPermissions",
		"fs.writeFile":             "WriteFile",
	}

	k := kite.New(options)
	k.AddMethods(new(Fs), methods)
	k.Start()
}

func (Fs) ReadDirectory(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {

	var params struct {
		Path                string
		OnChange            dnode.Callback
		WatchSubdirectories bool
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return errors.New("{ path: [string], onChange: [function], watchSubdirectories: [bool] }")
	}

	response := make(map[string]interface{})

	if params.OnChange != nil {
		onceBody := func() { startWatcher() }
		go once.Do(onceBody)

		// notify new paths to the watcher
		newPaths <- params.Path

		var event string
		var fileEntry *fsutils.FileEntry
		changer := func(ev *fsnotify.FileEvent) {
			if ev.IsCreate() {
				event = "added"
				fileEntry, _ = fsutils.GetInfo(ev.Name)
			} else if ev.IsDelete() {
				event = "removed"
				fileEntry = fsutils.NewFileEntry(path.Base(ev.Name), ev.Name)
			}

			params.OnChange(map[string]interface{}{
				"event": event,
				"file":  fileEntry,
			})
			return
		}

		watchCallbacks[params.Path] = changer

		// this callback is called whenever we receive a 'stopWatching' from the client
		response["stopWatching"] = func() {
			delete(watchCallbacks, params.Path)
			oldPaths <- params.Path
		}
	}

	files, err := fsutils.ReadDirectory(params.Path)
	if err != nil {
		return err
	}

	response["files"] = files
	*result = response
	return nil
}

func (Fs) Glob(r *protocol.KiteDnodeRequest, result *[]string) error {
	var params struct {
		Pattern string
	}

	if r.Args.Unmarshal(&params) != nil || params.Pattern == "" {
		return errors.New("{ pattern: [string] }")
	}

	files, err := fsutils.Glob(params.Pattern)
	if err != nil {
		return err
	}

	*result = files
	return nil
}

func (Fs) ReadFile(r *protocol.KiteDnodeRequest, result *map[string]interface{}) error {
	var params struct {
		Path string
	}
	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return errors.New("{ path: [string] }")
	}

	buf, err := fsutils.ReadFile(params.Path)
	if err != nil {
		return err
	}

	*result = map[string]interface{}{"content": buf}
	return nil
}

func (Fs) WriteFile(r *protocol.KiteDnodeRequest, result *string) error {
	var params struct {
		Path           string
		Content        []byte
		DoNotOverwrite bool
		Append         bool
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" || params.Content == nil {
		return errors.New("{ path: [string], content: [base64], doNotOverwrite: [bool], append: [bool] }")
	}

	err := fsutils.WriteFile(params.Path, params.Content, params.DoNotOverwrite, params.Append)
	if err != nil {
		return err
	}

	*result = fmt.Sprintf("content written to %s", params.Path)
	return nil
}

func (Fs) EnsureNonexistentPath(r *protocol.KiteDnodeRequest, result *string) error {
	var params struct {
		Path string
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return errors.New("{ path: [string] }")
	}

	name, err := fsutils.EnsureNonexistentPath(params.Path)
	if err != nil {
		return err
	}

	*result = name
	return nil
}

func (Fs) GetInfo(r *protocol.KiteDnodeRequest, result *fsutils.FileEntry) error {
	var params struct {
		Path string
	}
	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return errors.New("{ path: [string] }")
	}

	fileEntry, err := fsutils.GetInfo(params.Path)
	if err != nil {
		return err
	}

	*result = *fileEntry
	return nil
}

func (Fs) SetPermissions(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Path      string
		Mode      os.FileMode
		Recursive bool
	}
	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return errors.New("{ path: [string], mode: [integer], recursive: [bool] }")
	}

	err := fsutils.SetPermissions(params.Path, params.Mode, params.Recursive)
	if err != nil {
		return err
	}

	*result = true
	return nil

}

func (Fs) Remove(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Path      string
		Recursive bool
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return errors.New("{ path: [string], recursive: [bool] }")
	}

	err := fsutils.Remove(params.Path)
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (Fs) Rename(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		OldPath string
		NewPath string
	}

	if r.Args.Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return errors.New("{ oldPath: [string], newPath: [string] }")
	}

	err := fsutils.Rename(params.OldPath, params.NewPath)
	if err != nil {
		return err
	}

	*result = true
	return nil
}

func (Fs) CreateDirectory(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Path      string
		Recursive bool
	}
	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return errors.New("{ path: [string], recursive: [bool] }")
	}

	err := fsutils.CreateDirectory(params.Path, params.Recursive)
	if err != nil {
		return err
	}
	*result = true
	return nil
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
