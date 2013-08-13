package main

import (
	"exp/inotify"
	"fmt"
	"io"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/log"
	"koding/virt"
	"os"
	"path"
	"regexp"
	"strconv"
	"sync"
	"time"
)

var watcher *inotify.Watcher
var watchMap = make(map[string][]*Watch)
var watchMutex sync.Mutex

func init() {
	var err error
	watcher, err = inotify.NewWatcher()
	if err != nil {
		panic(err)
	}

	go func() {
		for ev := range watcher.Event {
			if (ev.Mask & (inotify.IN_CREATE | inotify.IN_MOVED_TO | inotify.IN_ATTRIB)) != 0 {
				info, err := os.Lstat(ev.Name)
				if err != nil {
					if os.IsNotExist(err) {
						continue // skip this event, file is deleted and deletion event will follow
					}
					log.Warn("Watcher error", err)
					continue
				}
				watchMutex.Lock()
				for _, watch := range watchMap[path.Dir(ev.Name)] {
					watch.Callback(map[string]interface{}{
						"event": "added",
						"file":  makeFileEntry(watch.VOS, path.Dir(ev.Name), info),
					})
				}
				watchMutex.Unlock()
				continue
			}
			if (ev.Mask & (inotify.IN_DELETE | inotify.IN_MOVED_FROM)) != 0 {
				watchMutex.Lock()
				for _, watch := range watchMap[path.Dir(ev.Name)] {
					watch.Callback(map[string]interface{}{
						"event": "removed",
						"file":  FileEntry{Name: path.Base(ev.Name)},
					})
				}
				watchMutex.Unlock()
				continue
			}
		}
	}()
	go func() {
		for err := range watcher.Error {
			log.Warn("Watcher error", err)
		}
	}()
}

func registerFileSystemMethods(k *kite.Kite) {
	registerVmMethod(k, "fs.readDirectory", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Path                string
			OnChange            dnode.Callback
			WatchSubdirectories bool
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], onChange: [function], watchSubdirectories: [bool] }"}
		}

		response := make(map[string]interface{})

		if params.OnChange != nil {
			watch := &Watch{VOS: vos, Callback: params.OnChange}
			if err := addWatch(watch, params.Path, params.WatchSubdirectories); err != nil {
				watch.Close()
				return nil, err
			}
			channel.OnDisconnect(func() { watch.Close() })
			response["stopWatching"] = func() { watch.Close() }
		}

		dir, err := vos.Open(params.Path)
		if err != nil {
			return nil, err
		}
		defer dir.Close()

		infos, err := dir.Readdir(0)
		if err != nil {
			return nil, err
		}

		files := make([]FileEntry, len(infos))
		for i, info := range infos {
			files[i] = makeFileEntry(vos, params.Path, info)
		}
		response["files"] = files

		return response, nil
	})

	registerVmMethod(k, "fs.readFile", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Path string
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
		}

		file, err := vos.Open(params.Path)
		if err != nil {
			return nil, err
		}
		defer file.Close()

		fi, err := file.Stat()
		if err != nil {
			return nil, err
		}

		if fi.Size() > 10*1024*1024 {
			return nil, fmt.Errorf("File larger than 10MiB.")
		}

		buf := make([]byte, fi.Size())
		if _, err := io.ReadFull(file, buf); err != nil {
			return nil, err
		}

		return map[string]interface{}{"content": buf}, nil
	})

	registerVmMethod(k, "fs.writeFile", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Path           string
			Content        []byte
			DoNotOverwrite bool
		}
		if args.Unmarshal(&params) != nil || params.Path == "" || params.Content == nil {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], content: [base64], doNotOverwrite: [bool] }"}
		}

		flags := os.O_RDWR | os.O_CREATE | os.O_TRUNC
		if params.DoNotOverwrite {
			flags |= os.O_EXCL
		}
		file, err := vos.OpenFile(params.Path, flags, 0666)
		if err != nil {
			return nil, err
		}
		defer file.Close()

		return file.Write(params.Content)
	})

	suffixRegexp, err := regexp.Compile(`.((_\d+)?)(\.\w*)?$`)
	if err != nil {
		panic(err)
	}

	registerVmMethod(k, "fs.ensureNonexistentPath", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Path string
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
		}

		name := params.Path
		index := 1
		for {
			_, err := vos.Stat(name)
			if err != nil {
				if os.IsNotExist(err) {
					break
				}
				return nil, err
			}

			loc := suffixRegexp.FindStringSubmatchIndex(name)
			name = name[:loc[2]] + "_" + strconv.Itoa(index) + name[loc[3]:]
			index++
		}

		return name, nil
	})

	registerVmMethod(k, "fs.getInfo", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Path string
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
		}

		fi, err := vos.Stat(params.Path)
		if err != nil {
			if os.IsNotExist(err) {
				return nil, nil
			}
			return nil, err
		}

		return makeFileEntry(vos, path.Dir(params.Path), fi), nil
	})

	registerVmMethod(k, "fs.setPermissions", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Path      string
			Mode      os.FileMode
			Recursive bool
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], mode: [integer], recursive: [bool] }"}
		}

		var doChange func(name string) error
		doChange = func(name string) error {
			if err := vos.Chmod(name, params.Mode); err != nil {
				return err
			}
			if !params.Recursive {
				return nil
			}
			fi, err := vos.Stat(name)
			if err != nil {
				return err
			}
			if !fi.IsDir() {
				return nil
			}
			dir, err := vos.Open(name)
			if err != nil {
				return err
			}
			defer dir.Close()
			entries, err := dir.Readdirnames(0)
			if err != nil {
				return err
			}
			var firstErr error
			for _, entry := range entries {
				err := doChange(name + "/" + entry)
				if err != nil && firstErr == nil {
					firstErr = err
				}
			}
			return firstErr
		}
		if err := doChange(params.Path); err != nil {
			return nil, err
		}

		return true, nil
	})

	registerVmMethod(k, "fs.remove", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Path      string
			Recursive bool
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
		}

		if params.Recursive {
			if err := vos.RemoveAll(params.Path); err != nil {
				return nil, err
			}
			return true, nil
		}

		if err := vos.Remove(params.Path); err != nil {
			return nil, err
		}
		return true, nil
	})

	registerVmMethod(k, "fs.rename", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			OldPath string
			NewPath string
		}
		if args.Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
			return nil, &kite.ArgumentError{Expected: "{ oldPath: [string], newPath: [string] }"}
		}

		if err := vos.Rename(params.OldPath, params.NewPath); err != nil {
			return nil, err
		}

		return true, nil
	})

	registerVmMethod(k, "fs.createDirectory", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Path      string
			Recursive bool
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
		}

		if params.Recursive {
			if err := vos.MkdirAll(params.Path, 0755); err != nil {
				return nil, err
			}
			return true, nil
		}

		if err := vos.Mkdir(params.Path, 0755); err != nil {
			return nil, err
		}
		return true, nil
	})
}

type Watch struct {
	VOS      *virt.VOS
	Paths    []string
	Callback dnode.Callback
}

func addWatch(watch *Watch, path string, watchSubdirectories bool) error {
	if len(watch.Paths) >= 100 {
		return fmt.Errorf("Too many subdirectories to watch.")
	}

	watchMutex.Lock()
	watchedPath, err := watch.VOS.AddWatch(watcher, path, inotify.IN_CREATE|inotify.IN_DELETE|inotify.IN_MOVE|inotify.IN_ATTRIB)
	if err != nil {
		watchMutex.Unlock()
		return err
	}
	watch.Paths = append(watch.Paths, watchedPath)
	watchMap[watchedPath] = append(watchMap[watchedPath], watch)
	watchMutex.Unlock()

	if watchSubdirectories {
		dir, err := watch.VOS.Open(path)
		if err != nil {
			return err
		}
		defer dir.Close()

		infos, err := dir.Readdir(0)
		if err != nil {
			return err
		}

		for _, info := range infos {
			if info.Mode().IsDir() {
				if err := addWatch(watch, path+"/"+info.Name(), true); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

func (watch *Watch) Close() error {
	watchMutex.Lock()
	defer watchMutex.Unlock()

	for _, path := range watch.Paths {
		watches := watchMap[path]
		for i, w := range watches {
			if w == watch {
				watches[i] = watches[len(watches)-1]
				watches = watches[:len(watches)-1]
				break
			}
		}
		watchMap[path] = watches
		if len(watches) == 0 {
			return watcher.RemoveWatch(path)
		}
	}

	return nil
}

type FileEntry struct {
	Name     string      `json:"name"`
	IsDir    bool        `json:"isDir"`
	Size     int64       `json:"size"`
	Mode     os.FileMode `json:"mode"`
	Time     time.Time   `json:"time"`
	IsBroken bool        `json:"isBroken"`
	Readable bool        `json:"readable"`
	Writable bool        `json:"writable"`
}

func makeFileEntry(vos *virt.VOS, dir string, fi os.FileInfo) FileEntry {
	entry := FileEntry{
		Name:     fi.Name(),
		IsDir:    fi.IsDir(),
		Size:     fi.Size(),
		Mode:     fi.Mode(),
		Time:     fi.ModTime(),
		Readable: vos.IsReadable(fi),
		Writable: vos.IsWritable(fi),
	}

	if fi.Mode()&os.ModeSymlink != 0 {
		symlinkInfo, err := vos.Stat(dir + "/" + fi.Name())
		if err != nil {
			entry.IsBroken = true
			return entry
		}
		entry.IsDir = symlinkInfo.IsDir()
		entry.Size = symlinkInfo.Size()
		entry.Mode = symlinkInfo.Mode()
		entry.Time = symlinkInfo.ModTime()
	}

	return entry
}
