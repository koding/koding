// +build linux

package main

import (
	"fmt"
	"io"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os"
	"path"
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
	Time     time.Time   `json:"time" dnode:"-"`
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

func fsReadDirectoryOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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

func fsGlobOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Pattern string
	}

	if args.Unmarshal(&params) != nil || params.Pattern == "" {
		return nil, &kite.ArgumentError{Expected: "{ pattern: [string] }"}
	}

	return fsGlob(params.Pattern, vos)
}

func fsReadFileOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}

	if args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsReadFile(params.Path, vos)
}

func fsWriteFileOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params writeFileParams

	if args.Unmarshal(&params) != nil || params.Path == "" || params.Content == nil {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], content: [base64], doNotOverwrite: [bool], append: [bool] }"}
	}

	return fsWriteFile(params, vos)
}

func fsUniquePathOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}
	if args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsUniquePath(params.Path, vos)
}

func fsGetInfoOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}
	if args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsGetInfo(params.Path, vos)
}

func fsSetPermissionsOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params setPermissionsParams

	if args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], mode: [integer], recursive: [bool] }"}
	}

	return fsSetPermissions(params, vos)
}

func fsRemoveOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path      string
		Recursive bool
	}
	if args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
	}

	return fsRemove(params.Path, params.Recursive, vos)
}

func fsRenameOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		OldPath string
		NewPath string
	}
	if args.Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ oldPath: [string], newPath: [string] }"}
	}

	return fsRename(params.OldPath, params.NewPath, vos)
}

func fsCreateDirectoryOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path      string
		Recursive bool
	}
	if args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
	}

	return fsCreateDirectory(params.Path, params.Recursive, vos)
}

func fsMoveOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		OldPath string
		NewPath string
	}

	if args.Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ oldPath: [string], newPath: [string] }"}
	}

	return fsMove(params.OldPath, params.NewPath, vos)
}

func fsCopyOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		SrcPath string
		DstPath string
	}

	if args.Unmarshal(&params) != nil || params.SrcPath == "" || params.DstPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ srcPath: [string], dstPath: [string] }"}
	}

	return fsCopy(params.SrcPath, params.DstPath, vos)
}

//////////////////////

func fsGlob(pattern string, vos *virt.VOS) (interface{}, error) {
	matches, err := vos.Glob(pattern)
	if err == nil && matches == nil {
		matches = []string{}
	}

	return matches, err
}

func fsReadFile(path string, vos *virt.VOS) (interface{}, error) {
	file, err := vos.Open(path)
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

type writeFileParams struct {
	Path           string
	Content        []byte
	DoNotOverwrite bool
	Append         bool
}

func fsWriteFile(params writeFileParams, vos *virt.VOS) (interface{}, error) {
	newPath, err := vos.UniquePath(params.Path)
	if err != nil {
		return nil, err
	}
	params.Path = newPath

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

	_, err = file.Write(params.Content)
	if err != nil {
		return nil, err
	}

	fi, err := file.Stat()
	if err != nil {
		return nil, err
	}

	return makeFileEntry(vos, params.Path, fi), nil
}

func fsUniquePath(path string, vos *virt.VOS) (interface{}, error) {
	return vos.UniquePath(path)
}

func fsGetInfo(path string, vos *virt.VOS) (interface{}, error) {
	fi, err := vos.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}

	return makeFileEntry(vos, path, fi), nil
}

type setPermissionsParams struct {
	Path      string
	Mode      os.FileMode
	Recursive bool
}

func fsSetPermissions(params setPermissionsParams, vos *virt.VOS) (interface{}, error) {
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

func fsRemove(removePath string, recursive bool, vos *virt.VOS) (interface{}, error) {
	if recursive {
		if err := vos.RemoveAll(removePath); err != nil {
			return nil, err
		}
		return true, nil
	}

	if err := vos.Remove(removePath); err != nil {
		return nil, err
	}
	return true, nil
}

func fsRename(oldpath, newpath string, vos *virt.VOS) (interface{}, error) {
	var err error
	newpath, err = vos.UniquePath(newpath)
	if err != nil {
		return nil, err
	}

	if err := vos.Rename(oldpath, newpath); err != nil {
		return nil, err
	}

	fi, err := vos.Stat(newpath)
	if err != nil {
		return nil, err
	}

	return makeFileEntry(vos, newpath, fi), nil
}

func fsCreateDirectory(newPath string, recursive bool, vos *virt.VOS) (interface{}, error) {
	var err error
	newPath, err = vos.UniquePath(newPath)
	if err != nil {
		return nil, err
	}

	if recursive {
		if err := vos.MkdirAll(newPath, 0755); err != nil {
			return nil, err
		}
		return true, nil
	}

	dirInfo, err := vos.Stat(path.Dir(newPath))
	if err != nil {
		return nil, err
	}

	if err := vos.Mkdir(newPath, dirInfo.Mode().Perm()); err != nil {
		return nil, err
	}

	return makeFileEntry(vos, newPath, dirInfo), nil
}

func fsMove(oldPath, newPath string, vos *virt.VOS) (interface{}, error) {
	if err := vos.Rename(oldPath, newPath); err != nil {
		return nil, err
	}

	return true, nil
}

func fsCopy(srcPath, dstPath string, vos *virt.VOS) (interface{}, error) {
	if err := vos.Copy(srcPath, dstPath); err != nil {
		return nil, err
	}

	return true, nil
}
