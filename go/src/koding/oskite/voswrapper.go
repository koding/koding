// +build linux

package oskite

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kodingkite"
	"koding/tools/kite"
	"koding/virt"
	"os"
	"path"
	"strings"

	kitelib "github.com/koding/kite"
	kitednode "github.com/koding/kite/dnode"
	"github.com/koding/kite/protocol"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"code.google.com/p/go.exp/inotify"
)

// vosFunc is used to associate each request with a VOS instance.
type vosFunc func(*kitelib.Request, *virt.VOS) (interface{}, error)

// vosMethod is compat wrapper around the new kite library. It's basically
// creates a vos instance that is the plugged into the the base functions.
func (o *Oskite) vosMethod(k *kodingkite.KodingKite, method string, vosFn vosFunc) {
	handler := func(r *kitelib.Request) (interface{}, error) {
		var params struct {
			VmName string
		}

		if err := r.Args.One().Unmarshal(&params); err != nil {
			return nil, err
		}

		if params.VmName == "" {
			return nil, errors.New("{ vmName: [string]}")
		}

		vos, err := o.getVos(r.Username, params.VmName)
		if err != nil {
			return nil, err
		}

		info := getInfo(vos.VM)
		info.stopTimeoutNewKite(k)

		return vosFn(r, vos)
	}
	k.HandleFunc(method, handler)

}

// getVos returns a new VOS based on the given username and vmName
// which is used to pick up the correct VM.
func (o *Oskite) getVos(username, vmName string) (*virt.VOS, error) {
	user, err := o.getUser(username)
	if err != nil {
		return nil, err
	}

	vm, err := checkAndGetVM(username, vmName)
	if err != nil {
		return nil, err
	}

	err = o.validateVM(vm)
	if err != nil {
		return nil, err
	}

	permissions := vm.GetPermissions(user)
	if permissions == nil && user.Uid != virt.RootIdOffset {
		return nil, errors.New("Permission denied.")
	}

	return &virt.VOS{
		VM:          vm,
		User:        user,
		Permissions: permissions,
	}, nil
}

// checkAndGetVM returns a new virt.VM struct based on on the given username
// and vm name. If the user doesn't have any associated VM it returns a
// VMNotFoundError.
func checkAndGetVM(username, vmName string) (*virt.VM, error) {
	var vm *virt.VM

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"hostnameAlias": vmName,
			"webHome":       username,
		}).One(&vm)
	}

	if err := mongodbConn.Run("jVMs", query); err != nil {
		return nil, &VMNotFoundError{Name: vmName}
	}

	vm.ApplyDefaults()
	return vm, nil
}

func (o *Oskite) kiteWho(r *kitelib.Request) (interface{}, error) {
	var params struct {
		VmName string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.VmName == "" {
		return nil, &kite.ArgumentError{Expected: "[string]"}
	}

	var vm *virt.VM
	if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Find(bson.M{"hostnameAlias": params.VmName}).One(&vm)
	}); err != nil {
		log.Error("kite.who err: %v", err)
		return nil, errors.New("not found")
	}

	resultOskite := lowestOskiteLoad()
	if resultOskite == "" {
		resultOskite = o.ServiceUniquename
	}

	hostKite := vm.HostKite
	if vm.HostKite == "" {
		hostKite = resultOskite
	}

	if vm.HostKite == "(maintenance)" {
		return nil, errors.New("hostkite is under maintenance")
	}

	if vm.HostKite == "(banned)" {
		return nil, errors.New("hostkite is marked as (banned)")
	}

	if vm.PinnedToHost != "" {
		hostKite = vm.PinnedToHost

	}

	// hostKite is in form: "kite-os-sj|kontainer1_sj_koding_com"
	s := strings.Split(hostKite, "|")
	if len(s) < 2 {
		return nil, fmt.Errorf("hostkite '%s' is malformed", hostKite)
	}

	// s[1] -> kontainer1_sj_koding_com
	hostname := strings.Replace(s[1], "_", ".", -1)

	proc := o.NewKite.Kite()
	query := protocol.KontrolQuery{
		Username:    proc.Username,
		Environment: proc.Environment,
		Name:        proc.Name,
		Version:     proc.Version,
		Region:      proc.Region,
		Hostname:    hostname,
	}

	return &protocol.WhoResult{
		Query: query,
	}, nil
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

func vmReinitializeNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmReinitialize(vos)
}

func vmInfoNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmInfo(vos)
}

func vmResizeDiskNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmResizeDisk(vos)
}

func vmCreateSnapshotNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmCreateSnapshot(vos)
}

func spawnFuncNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Command []string
	}

	if r.Args.One().Unmarshal(&params) != nil || len(params.Command) == 0 {
		return nil, &kite.ArgumentError{Expected: "{command : [array of strings]}"}
	}

	return spawnFunc(params.Command, vos)
}

func execFuncNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Command  string
		Password string
		Async    bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Command == "" {
		return nil, &kite.ArgumentError{Expected: "{Command : [string]}"}
	}

	asRoot := false
	if params.Password != "" {
		_, err := modelhelper.CheckAndGetUser(r.Username, params.Password)
		if err != nil {
			return nil, errors.New("Permissiond denied. Wrong password")
		}

		asRoot = true
	}

	if params.Async {
		go execFunc(asRoot, params.Command, vos)
		return true, nil
	}

	return execFunc(asRoot, params.Command, vos)
}

func (o *Oskite) vmPrepareAndStartNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	params := new(vmParamsNew)
	if r.Args.One().Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	if params.GroupId == "" {
		return nil, &kite.ArgumentError{Expected: "{ groupId: [string] }"}
	}

	return o.prepareAndStart(vos, r.Username, params.GroupId, params)
}

func vmStopAndUnprepareNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	params := new(vmParamsNew)
	if r.Args.One().Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	if params.Enabled() {
		go unprepareProgress(params, vos.VM, params.Destroy)
		return true, nil
	}

	if err := unprepareProgress(nil, vos.VM, params.Destroy); err != nil {
		return nil, err
	}

	return true, nil
}

// FS METHODS

// TODO: replace watcher with fsnotify.
func fsReadDirectoryNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path                string
		OnChange            kitednode.Function
		WatchSubdirectories bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], onChange: [function], watchSubdirectories: [bool] }"}
	}

	response := make(map[string]interface{})

	if params.OnChange.IsValid() {
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
				params.OnChange.Call(map[string]interface{}{
					"event": event,
					"file":  makeFileEntry(vos, ev.Name, info),
				})
				return
			}

			if (ev.Mask & (inotify.IN_DELETE | inotify.IN_MOVED_FROM)) != 0 {
				params.OnChange.Call(map[string]interface{}{
					"event": "removed",
					"file":  FileEntry{Name: path.Base(ev.Name), FullPath: ev.Name},
				})
				return
			}
		})
		if err != nil {
			return nil, err
		}

		r.Client.OnDisconnect(func() { watch.Close() })

		response["stopWatching"] = kitednode.Callback(func(args *kitednode.Partial) {
			watch.Close()
		})

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

	if r.Args.One().Unmarshal(&params) != nil || params.Pattern == "" {
		return nil, &kite.ArgumentError{Expected: "{ pattern: [string] }"}
	}

	return fsGlob(params.Pattern, vos)
}

func fsReadFileNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsReadFile(params.Path, vos)
}

func fsWriteFileNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params writeFileParams
	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsWriteFile(params, vos)
}

func fsUniquePathNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsUniquePath(params.Path, vos)
}

func fsGetInfoNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string] }"}
	}

	return fsGetInfo(params.Path, vos)
}

func fsSetPermissionsNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params setPermissionsParams

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], mode: [integer], recursive: [bool] }"}
	}

	return fsSetPermissions(params, vos)
}

func fsRemoveNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path      string
		Recursive bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
	}

	return fsRemove(params.Path, params.Recursive, vos)
}

func fsRenameNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		OldPath string
		NewPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ oldPath: [string], newPath: [string] }"}
	}

	return fsRename(params.OldPath, params.NewPath, vos)
}

func fsCreateDirectoryNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Path      string
		Recursive bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, &kite.ArgumentError{Expected: "{ path: [string], recursive: [bool] }"}
	}

	return fsCreateDirectory(params.Path, params.Recursive, vos)
}

func fsMoveNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		OldPath string
		NewPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.OldPath == "" || params.NewPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ oldPath: [string], newPath: [string] }"}
	}

	return fsMove(params.OldPath, params.NewPath, vos)
}

func fsCopyNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		SrcPath string
		DstPath string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.SrcPath == "" || params.DstPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ srcPath: [string], dstPath: [string] }"}
	}

	return fsCopy(params.SrcPath, params.DstPath, vos)
}

// APP METHODS
func appInstallNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params appParams
	if r.Args.One().Unmarshal(&params) != nil || params.Owner == "" || params.Identifier == "" || params.Version == "" || params.AppPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ owner: [string], identifier: [string], version: [string], appPath: [string] }"}
	}

	return appInstall(params, vos)

}

func appDownloadNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params appParams
	if r.Args.One().Unmarshal(&params) != nil || params.Owner == "" || params.Identifier == "" || params.Version == "" || params.AppPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ owner: [string], identifier: [string], version: [string], appPath: [string] }"}
	}

	return appDownload(params, vos)
}

func appPublishNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params appParams
	if r.Args.One().Unmarshal(&params) != nil || params.AppPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ appPath: [string] }"}
	}

	return appPublish(params, vos)
}

func appSkeletonNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params appParams
	if r.Args.One().Unmarshal(&params) != nil || params.AppPath == "" {
		return nil, &kite.ArgumentError{Expected: "{ type: [string], appPath: [string] }"}
	}

	return appSkeleton(params, vos)
}

func s3StoreNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	params := new(storeParams)
	if r.Args.One().Unmarshal(&params) != nil || params.Name == "" || len(params.Content) == 0 || strings.Contains(params.Name, "/") {
		return nil, &kite.ArgumentError{Expected: "{ name: [string], content: [base64 string] }"}
	}

	return s3Store(params, vos)
}

func s3DeleteNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	params := new(storeParams)
	if r.Args.One().Unmarshal(&params) != nil || params.Name == "" || strings.Contains(params.Name, "/") {
		return nil, &kite.ArgumentError{Expected: "{ name: [string] }"}
	}

	return s3Delete(params, vos)
}
