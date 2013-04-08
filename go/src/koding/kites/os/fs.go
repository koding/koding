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

type Watch struct {
	VOS      *virt.VOS
	Path     string
	Callback dnode.Callback
}

type FileEntry struct {
	Name     string      `json:"name"`
	IsDir    bool        `json:"isDir"`
	Size     int64       `json:"size"`
	Mode     os.FileMode `json:"mode"`
	Time     time.Time   `json:"time"`
	IsBroken bool        `json:"isBroken"`
}

func init() {
	var err error
	watcher, err = inotify.NewWatcher()
	if err != nil {
		panic(err)
	}

	go func() {
		for ev := range watcher.Event {
			if (ev.Mask & (inotify.IN_CREATE | inotify.IN_MODIFY | inotify.IN_MOVED_TO)) != 0 {
				info, err := os.Lstat(ev.Name)
				if err != nil {
					log.Warn("Watcher error", err)
					continue
				}
				watchMutex.Lock()
				for _, watch := range watchMap[path.Dir(ev.Name)] {
					watch.Callback(map[string]interface{}{
						"event": "added",
						"file":  makeFileEntry(watch.VOS, watch.Path, info),
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
	k.Handle("fs.readDirectory", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path     string
			OnChange dnode.Callback
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], onChange: [function] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)
		response := make(map[string]interface{})

		if params.OnChange != nil {
			watchedPath, err := vos.AddWatch(watcher, params.Path, inotify.IN_CREATE|inotify.IN_DELETE|inotify.IN_MODIFY|inotify.IN_MOVE)
			if err != nil {
				return nil, err
			}

			watchMutex.Lock()
			defer watchMutex.Unlock()

			watch := &Watch{vos, watchedPath, params.OnChange}
			watchMap[watchedPath] = append(watchMap[watchedPath], watch)
			session.OnDisconnect(func() { watch.Close() })
			response["stopWatching"] = func() { watch.Close() }
		}

		dir, err := vos.Open(params.Path)
		defer dir.Close()
		if err != nil {
			return nil, err
		}

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

	k.Handle("fs.readFile", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path string
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

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

	k.Handle("fs.writeFile", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path           string
			Content        []byte
			DoNotOverwrite bool
		}
		if args.Unmarshal(&params) != nil || params.Path == "" || params.Content == nil {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], content: [base64], doNotOverwrite: [bool] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

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

	suffixRegexp, err := regexp.Compile(`((_\d+)?)(\.\w*)?$`)
	if err != nil {
		panic(err)
	}

	k.Handle("fs.ensureNonexistentPath", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path string
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

		name := params.Path
		index := 1
		for {
			_, err := vos.Stat(name)
			if err != nil {
				if os.IsNotExist(err) {
					break
				}
				panic(err)
			}

			loc := suffixRegexp.FindStringSubmatchIndex(name)
			name = name[:loc[2]] + "_" + strconv.Itoa(index) + name[loc[3]:]
			index++
		}

		return name, nil
	})

	k.Handle("fs.getInfo", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path string
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

		fi, err := vos.Stat(params.Path)
		if err != nil {
			if os.IsNotExist(err) {
				return nil, nil
			}
			return nil, err
		}

		return makeFileEntry(vos, path.Dir(params.Path), fi), nil
	})

	k.Handle("fs.setPermissions", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path string
			Mode os.FileMode
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], mode: [integer] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

		if err := vos.Chmod(params.Path, params.Mode); err != nil {
			return nil, err
		}

		return true, nil
	})

	k.Handle("fs.remove", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path      string
			Recursive bool
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

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

	k.Handle("fs.rename", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			OldPath string
			NewPath string
		}
		if args.Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
			return nil, &kite.ArgumentError{Expected: "{ oldPath: [string], newPath: [string] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

		if err := vos.Rename(params.OldPath, params.NewPath); err != nil {
			return nil, err
		}

		return true, nil
	})

	k.Handle("fs.createDirectory", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Path string
		}
		if args.Unmarshal(&params) != nil || params.Path == "" {
			return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
		}

		user, vm := findSession(session)
		vos := vm.OS(user)

		if err := vos.Mkdir(params.Path, 0755); err != nil {
			return nil, err
		}

		return true, nil
	})
}

func (watch *Watch) Close() error {
	watchMutex.Lock()
	defer watchMutex.Unlock()

	watches := watchMap[watch.Path]
	for i, w := range watches {
		if w == watch {
			watches[i] = watches[len(watches)-1]
			watches = watches[:len(watches)-1]
			break
		}
	}

	watchMap[watch.Path] = watches

	if len(watches) == 0 {
		return watcher.RemoveWatch(watch.Path)
	}

	return nil
}

func makeFileEntry(vos *virt.VOS, dir string, fi os.FileInfo) FileEntry {
	entry := FileEntry{
		Name:  fi.Name(),
		IsDir: fi.IsDir(),
		Size:  fi.Size(),
		Mode:  fi.Mode(),
		Time:  fi.ModTime(),
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
