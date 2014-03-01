// +build linux

package oskite

import (
	"fmt"
	"io"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os"
	"path"
	"regexp"
	"strconv"
	"time"

	"code.google.com/p/go.exp/inotify"
)

func init() {
	go func() {
		for err := range virt.WatchErrors {
			log.Warning("Watcher error", err)
		}
	}()
}

type FileEntry struct {
	Name     string      `json:"name"`
	FullPath string      `json:"fullPath"`
	IsDir    bool        `json:"isDir"`
	Size     int64       `json:"size"`
	Mode     os.FileMode `json:"mode"`
	Time     time.Time   `json:"time"`
	IsBroken bool        `json:"isBroken"`
	Readable bool        `json:"readable"`
	Writable bool        `json:"writable"`
}

func makeFileEntry(vos *virt.VOS, fullPath string, fi os.FileInfo) FileEntry {
	entry := FileEntry{
		Name:     fi.Name(),
		FullPath: fullPath,
		IsDir:    fi.IsDir(),
		Size:     fi.Size(),
		Mode:     fi.Mode(),
		Time:     fi.ModTime(),
		Readable: vos.IsReadable(fi),
		Writable: vos.IsWritable(fi),
	}

	if fi.Mode()&os.ModeSymlink != 0 {
		symlinkInfo, err := vos.Stat(path.Dir(fullPath) + "/" + fi.Name())
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

func fsReadDirectory(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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
		watch, err := vos.WatchDirectory(params.Path, params.WatchSubdirectories, func(ev *inotify.Event, info os.FileInfo) {
			defer log.RecoverAndLog()

			if (ev.Mask & (inotify.IN_CREATE | inotify.IN_MOVED_TO | inotify.IN_ATTRIB)) != 0 {
				if info == nil {
					return // skip this event, file was deleted and deletion event will follow
				}
				event := "added"
				if ev.Mask&inotify.IN_ATTRIB != 0 {
					event = "attributesChanged"
				}
				params.OnChange(map[string]interface{}{
					"event": event,
					"file":  makeFileEntry(vos, ev.Name, info),
				})
				return
			}
			if (ev.Mask & (inotify.IN_DELETE | inotify.IN_MOVED_FROM)) != 0 {
				params.OnChange(map[string]interface{}{
					"event": "removed",
					"file":  FileEntry{Name: path.Base(ev.Name), FullPath: ev.Name},
				})
				return
			}
		})
		if err != nil {
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
		files[i] = makeFileEntry(vos, path.Join(params.Path, info.Name()), info)
	}
	response["files"] = files

	return response, nil
}

func fsGlob(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Pattern string
	}
	if args.Unmarshal(&params) != nil || params.Pattern == "" {
		return nil, &kite.ArgumentError{Expected: "{ pattern: [string] }"}
	}

	matches, err := vos.Glob(params.Pattern)
	if err == nil && matches == nil {
		matches = []string{}
	}
	return matches, err
}

func fsReadFile(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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
}

func fsWriteFile(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path           string
		Content        []byte
		DoNotOverwrite bool
		Append         bool
	}
	if args.Unmarshal(&params) != nil || params.Path == "" || params.Content == nil {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], content: [base64], doNotOverwrite: [bool], append: [bool] }"}
	}

	flags := os.O_RDWR | os.O_CREATE
	if params.DoNotOverwrite {
		flags |= os.O_EXCL
	}
	if !params.Append {
		flags |= os.O_TRUNC
	}
	dirInfo, err := vos.Stat(path.Dir(params.Path))
	if err != nil {
		return nil, err
	}
	file, err := vos.OpenFile(params.Path, flags, dirInfo.Mode().Perm()&0666)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	if params.Append {
		_, err := file.Seek(0, 2)
		if err != nil {
			return nil, err
		}
	}
	return file.Write(params.Content)
}

var suffixRegexp = regexp.MustCompile(`.((_\d+)?)(\.\w*)?$`)

func fsEnsureNonexistentPath(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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
}

func fsGetInfo(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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

	return makeFileEntry(vos, params.Path, fi), nil
}

func fsSetPermissions(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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
}

func fsRemove(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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
}

func fsRename(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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
}

func fsCreateDirectory(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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

	dirInfo, err := vos.Stat(path.Dir(params.Path))
	if err != nil {
		return nil, err
	}
	if err := vos.Mkdir(params.Path, dirInfo.Mode().Perm()); err != nil {
		return nil, err
	}
	return true, nil
}
