// Package fs provides file system handleFuncs that can be used with kite
// library
package fs

import (
	"errors"
	"log"
	"os"
	"path"
	"path/filepath"
	"sync"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"gopkg.in/fsnotify.v1"
)

var (
	once               sync.Once // watcher variables
	newPaths, oldPaths = make(chan string), make(chan string)

	// Limit of watching folders
	// user -> path callbacks
	watchCallbacks = make(map[string]map[string]func(fsnotify.Event), 100)
	mu             sync.Mutex // protects watchCallbacks
)

type ReadDirectoryOptions struct {
	Path     string
	OnChange dnode.Function

	// Recursive specifies if results contain info about nested file/folder.
	Recursive bool

	// IgnoreFolders specifies which folders to not return results for
	// when reading recursively.
	IgnoreFolders []string
}

type GetInfoOptions struct {
	Path string `json:"path"`
}

type GetFolderSizeOptions struct {
	Path string `json:"path"`
}

func ReadDirectory(r *kite.Request) (interface{}, error) {
	var params ReadDirectoryOptions
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

		var eventType string
		var fileEntry *FileEntry

		changer := func(ev fsnotify.Event) {
			switch ev.Op {
			case fsnotify.Create:
				eventType = "added"
				fileEntry, _ = getInfo(ev.Name)
			case fsnotify.Remove, fsnotify.Rename:
				eventType = "removed"
				fileEntry = NewFileEntry(path.Base(ev.Name), ev.Name)
			}

			event := map[string]interface{}{
				"event": eventType,
				"file":  fileEntry,
			}

			// send back the result to the client
			params.OnChange.Call(event)
			return
		}

		// first check if are watching the path, if not send it to the watcher
		mu.Lock()
		userCallbacks, ok := watchCallbacks[params.Path]
		if !ok {
			// notify new paths to the watcher
			newPaths <- params.Path
			userCallbacks = make(map[string]func(fsnotify.Event), 0)
		}

		// now add the callback to the specific user.
		_, ok = userCallbacks[r.Username]
		if !ok {
			userCallbacks[r.Username] = changer
			watchCallbacks[params.Path] = userCallbacks
		}
		mu.Unlock()

		removePath := func() {
			mu.Lock()
			userCallbacks, ok := watchCallbacks[params.Path]
			if ok {
				// delete the user callback function for this path
				delete(userCallbacks, r.Username)

				// now check if there is any user left back. If we have removed
				// all users, we should also stop the watcher from watching the
				// path. So notify the watcher to stop watching the path and
				// also remove it from the callbacks map
				if len(userCallbacks) == 0 {
					delete(watchCallbacks, params.Path)
					oldPaths <- params.Path
				}
			}
			mu.Unlock()
		}

		// remove the user or path when the remote client disconnects
		r.Client.OnDisconnect(removePath)

		// this callback is called whenever we receive a 'stopWatching' from the client
		response["stopWatching"] = dnode.Callback(func(r *dnode.Partial) {
			removePath()
		})
	}

	files, err := readDirectory(params.Path, params.Recursive, params.IgnoreFolders)
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
				err := watcher.Add(p)
				if err != nil {
					log.Println("watch path adding", err)
				}
			case p := <-oldPaths:
				err := watcher.Remove(p)
				if err != nil {
					log.Println("watch remove adding", err)
				}
			}
		}
	}()

	for {
		select {
		case event := <-watcher.Events:
			mu.Lock()
			callbacks, ok := watchCallbacks[path.Dir(event.Name)]
			mu.Unlock()

			if !ok {
				continue
			}

			// send the event to all callbacks added.
			for _, f := range callbacks {
				f(event)
			}

		case err := <-watcher.Errors:
			log.Println("watcher error:", err)
		}
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
		Path      string
		Offset    int64
		BlockSize int64
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	return readFile(params.Path, params.Offset, params.BlockSize)
}

type writeFileParams struct {
	Path           string
	Content        []byte
	DoNotOverwrite bool
	Append         bool

	// If specified, this option will cause fs.writeFile to hash the file on
	// filesystem and compare the hash to this value. If the values do not match,
	// an error is returned.
	//
	// The current hashing algorithm is md5
	LastContentHash string

	// Offset optionally writes the given data at the offset location, using
	// file.WriteAt(data,offset) instead of file.Write(data)
	Offset int64
}

func WriteFile(r *kite.Request) (interface{}, error) {
	var params writeFileParams
	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	return writeFile(params)
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
	var opts GetInfoOptions

	if r.Args.One().Unmarshal(&opts) != nil || opts.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	return getInfo(opts.Path)
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

// DiskInfo contains metadata about a mount.
type DiskInfo struct {
	BlockSize   uint32 `json:"blockSize"`
	BlocksTotal uint64 `json:"blocksTotal"`
	BlocksFree  uint64 `json:"blocksFree"`
	BlocksUsed  uint64 `json:"blocksUsed"`
	IOSize      int32  `json:"ioSize"`
}

// GetDiskInfo returns DiskInfo about the mount at the specified path.
func GetDiskInfo(r *kite.Request) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	di, err := Statfs(params.Path)
	if err != nil {
		return nil, err
	}

	return di, nil
}

func GetPathSize(r *kite.Request) (interface{}, error) {
	var opts GetFolderSizeOptions

	if r.Args.One().Unmarshal(&opts) != nil || opts.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	var total int64
	err := filepath.Walk(opts.Path, func(_ string, fi os.FileInfo, err error) error {
		if !fi.IsDir() {
			total += fi.Size()
		}

		return err
	})

	return total, err
}
