// +build linux

package main

import (
	"errors"
	kitelib "kite"
	kitednode "kite/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os"
	"path"

	"code.google.com/p/go.exp/inotify"
)

// vosFunc is used to associate each request with a VOS instance.
type vosFunc func(*kitelib.Request, *virt.VOS) (interface{}, error)

// vosMethod is compat wrapper around the new kite library. It's basically
// creates a vos instance that is the plugged into the the base functions.
func vosMethod(k *kitelib.Kite, method string, vosFn vosFunc) {
	handler := func(r *kitelib.Request) (interface{}, error) {
		var params struct {
			// might be vm ID or hostnameAlias
			CorrelationName string
		}

		if r.Args.One().Unmarshal(&params) != nil || params.CorrelationName == "" {
			return nil, errors.New("{ correlationName: [string]}")
		}

		vos, err := getVos(r.Username, params.CorrelationName)
		if err != nil {
			return nil, err
		}

		return vosFn(r, vos)
	}

	k.HandleFunc(method, handler)
}

// VM METHODS

func vmStartNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmStart(vos)
}

func vmStopNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmStop(vos)
}

func vmShutdownNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmShutdown(vos)
}

func vmUnprepareNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmUnprepare(vos)
}

func vmReinitializeNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmReinitialize(vos)
}

func vmInfoNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmInfo(vos)
}

func vmPrepareNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmPrepare(vos)
}

func vmResizeDiskNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmResizeDisk(vos)
}

func vmCreateSnapshotNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmCreateSnapshot(vos)
}

func spawnNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Command []string
	}

	if r.Args.One().Unmarshal(&params) != nil || len(params.Command) == 0 {
		return nil, &kite.ArgumentError{Expected: "[array of strings]"}
	}

	return spawn(params.Command, vos)
}

func execNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Line string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Line == "" {
		return nil, &kite.ArgumentError{Expected: "[string]"}
	}

	return exec(params.Line, vos)
}

// FS METHODS

// TODO: replace watcher with fsnotify.
func fsReadDirectoryNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path                string
		OnChange            kitednode.Function
		WatchSubdirectories bool
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
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

		r.RemoteKite.OnDisconnect(func() { watch.Close() })
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

func fsGlobNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Pattern string
	}

	if r.Args.Unmarshal(&params) != nil || params.Pattern == "" {
		return nil, &kite.ArgumentError{Expected: "{ pattern: [string] }"}
	}

	return fsGlob(params.Pattern, vos)
}

func fsReadFileNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsReadFile(params.Path, vos)
}

func fsWriteFileNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params writeFileParams
	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsWriteFile(params, vos)
}

func fsEnsureNonexistentPathNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsEnsureNonexistentPath(params.Path, vos)
}

func fsGetInfoNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsGetInfo(params.Path, vos)
}

func fsSetPermissionsNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params setPermissionsParams

	if r.Args.Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], mode: [integer], recursive: [bool] }"}
	}

	return fsSetPermissions(params, vos)
}
