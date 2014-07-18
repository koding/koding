// +build linux

package oskite

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"koding/db/mongodb/modelhelper"
	"koding/oskite/ldapserver"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/tracer"
	"koding/virt"
	"os"
	"os/exec"
	"syscall"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	ErrVmAlreadyPrepared = errors.New("vm is already prepared")
	ErrVmNotPrepared     = errors.New("vm is not prepared")
)

func vmStartOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmStart(vos)
}

func vmShutdownOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmShutdown(vos)
}

func vmStopOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmStop(vos)
}

func vmReinitializeOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmReinitialize(vos)
}

func vmInfoOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmInfo(vos)
}

func vmResizeDiskOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmResizeDisk(vos)
}

func vmCreateSnapshotOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmCreateSnapshot(vos)
}

func vmUsageOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmUsage(args, vos, c.Username)
}

func spawnFuncOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Command []string
	}

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil || len(params.Command) == 0 {
		return nil, &kite.ArgumentError{Expected: "{command : [array of strings]}"}
	}

	return spawnFunc(params.Command, vos)
}

func execFuncOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Command  string
		Password string
		Async    bool
	}

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.Command == "" {
		return nil, &kite.ArgumentError{Expected: "{Command : [string]}"}
	}

	asRoot := false
	if params.Password != "" {
		_, err := modelhelper.CheckAndGetUser(c.Username, params.Password)
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

////////////////////

type output struct {
	Stdout     string `json:"stdout"`
	Stderr     string `json:"stderr"`
	ExitStatus int    `json:"exitStatus"`
}

func newOutput(cmd *exec.Cmd) (interface{}, error) {
	stdoutBuffer, stderrBuffer := new(bytes.Buffer), new(bytes.Buffer)
	cmd.Stdout, cmd.Stderr = stdoutBuffer, stderrBuffer
	var exitStatus int

	err := cmd.Run()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); !ok {
			return nil, err // return if it's not an exitError
		} else {
			exitStatus = exitErr.Sys().(syscall.WaitStatus).ExitStatus()
		}
	}

	return output{
		Stdout:     stdoutBuffer.String(),
		Stderr:     stderrBuffer.String(),
		ExitStatus: exitStatus,
	}, nil
}

func execFunc(asRoot bool, line string, vos *virt.VOS) (interface{}, error) {
	if !asRoot {
		return newOutput(vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line))
	}

	args := []string{"--name", vos.VM.String()}
	args = append(args, "--", "/bin/bash", "-c", line)
	cmd := exec.Command("/usr/bin/lxc-attach", args...)
	cmd.Env = []string{"TERM=xterm-256color"}

	return newOutput(cmd)
}

func spawnFunc(command []string, vos *virt.VOS) (interface{}, error) {
	return newOutput(vos.VM.AttachCommand(vos.User.Uid, "", command...))
}

func vmStart(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	prepared, err := isVmPrepared(vos.VM)
	if err != nil {
		return nil, err
	}

	if !prepared {
		return nil, ErrVmNotPrepared
	}

	if err := vos.VM.Start(); err != nil {
		return nil, err
	}

	// wait until network is up
	if err := vos.VM.WaitUntilReady(); err != nil {
		return nil, err
	}

	if _, err := checkAndUpdateState(vos.VM.Id, vos.VM.State); err != nil {
		return nil, err
	}

	return true, nil
}

func vmShutdown(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	if err := vos.VM.Shutdown(); err != nil {
		return nil, err
	}

	if _, err := checkAndUpdateState(vos.VM.Id, vos.VM.State); err != nil {
		return nil, err
	}

	return true, nil
}

func vmStop(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	if err := vos.VM.Stop(); err != nil {
		return nil, err
	}

	if _, err := checkAndUpdateState(vos.VM.Id, vos.VM.State); err != nil {
		return nil, err
	}

	return true, nil
}

func vmCreateSnapshot(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	snippetId := bson.NewObjectId().Hex()
	if err := vos.VM.CreateConsistentSnapshot(snippetId); err != nil {
		return nil, err
	}

	return snippetId, nil
}

func vmResizeDisk(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	if err := vos.VM.Shutdown(); err != nil {
		return nil, err
	}

	prepared, err := isVmPrepared(vos.VM)
	if err != nil {
		return nil, err
	}

	if prepared {
		// errors are neglected by design
		vos.VM.Unprepare(nil, false)
	}

	if err := vos.VM.Prepare(nil, false); err != nil {
		return nil, err
	}

	// stop it before we resize
	if err := vos.VM.Shutdown(); err != nil {
		return nil, err
	}

	if err := vos.VM.ResizeRBD(); err != nil {
		return nil, err
	}

	if err := vos.VM.Start(); err != nil {
		return nil, err
	}

	return true, nil
}

func vmInfo(vos *virt.VOS) (interface{}, error) {
	prepared, err := isVmPrepared(vos.VM)
	if err != nil {
		return nil, err
	}

	info := getInfo(vos.VM)
	log.Info("[vm.info] getting state for VM [%s -%s]", vos.VM.Id, vos.VM.HostnameAlias)
	info.State, err = vos.VM.GetState()
	if err != nil {
		log.Error("[vm.info] getting state failed for VM [%s - %s], err: %s", vos.VM.Id, vos.VM.HostnameAlias, err)
	}
	info.Prepared = prepared

	infosMutex.Lock()
	infos[vos.VM.Id] = info
	infosMutex.Unlock()

	return info, nil
}

func isVmPrepared(vm *virt.VM) (bool, error) {
	isPrepared := true
	if _, err := os.Stat(vm.File("rootfs/dev")); err != nil {
		if !os.IsNotExist(err) {
			return false, err
		}

		isPrepared = false
	}

	return isPrepared, nil
}

func vmReinitialize(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	if err := vos.VM.Shutdown(); err != nil {
		return nil, err
	}

	// errors are neglected by design
	vos.VM.Unprepare(nil, false)

	if err := vos.VM.Prepare(nil, false); err != nil {
		return nil, err
	}

	return true, nil
}

func (o *Oskite) vmPrepareAndStart(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	params := new(vmParams)
	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	if params.GroupId == "" {
		return nil, &kite.ArgumentError{Expected: "{ groupId: [string] }"}
	}

	return o.prepareAndStart(vos, channel.Username, params.GroupId, params)
}

func (o *Oskite) prepareAndStart(vos *virt.VOS, username, groupId string, pre Preparer) (interface{}, error) {
	dlocksMu.Lock()
	dlock, ok := dlocks[username]
	if !ok {
		dlock = o.newDlock(username, time.Millisecond*100, time.Second*20) // create new distributed lock
		dlocks[username] = dlock
	}
	dlocksMu.Unlock()

	dlock.Lock()
	defer dlock.Unlock()

	usage, err := totalUsage(vos, groupId)
	if err != nil {
		log.Info("usage -1 [%s] err: %v", vos.VM.HostnameAlias, err)
		return nil, errors.New("usage couldn't be retrieved. please consult to support [1].")
	}

	limits, err := usage.prepareLimits(username, groupId)
	if err != nil {
		// pass back endpoint err to client
		if endpointErrs.Has(err) {
			return nil, err
		}

		log.Info("usage -2 [%s] err: %v", vos.VM.HostnameAlias, err)
		return nil, errors.New("usage couldn't be retrieved. please consult to support [2].")
	}

	if err := limits.check(); err != nil {
		return nil, err
	}

	err = o.validateVM(vos.VM)
	if err != nil {
		return nil, err
	}

	done := make(chan struct{}, 1)
	var t tracer.Tracer

	if pre.Enabled() {
		t = pre
		done = nil // not used anymore
	}

	prepareQueue <- &QueueJob{
		msg: "vm.prepareAndStart " + vos.VM.HostnameAlias,
		f: func() error {
			if pre.Enabled() {
				// mutexes and locks are needed because it's handled in the
				// queue.
				info := getInfo(vos.VM)
				info.mutex.Lock()
				defer info.mutex.Unlock()

				dlock.Lock()
				defer dlock.Unlock()
			} else {
				defer func() { done <- struct{}{} }()
			}

			if err := prepareProgress(t, vos.VM); err != nil {
				return err
			}

			return prepareHome(vos)
		},
	}

	// start preparing
	if !pre.Enabled() {
		<-done
		return true, err
	}

	return true, nil

}

func vmStopAndUnprepare(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	params := new(vmParams)
	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	done := make(chan struct{}, 1)
	var t tracer.Tracer
	var err error

	if params.Enabled() {
		t = params
		done = nil // not used anymore
	}

	prepareQueue <- &QueueJob{
		msg: "vm.stopAndUnprepare " + vos.VM.HostnameAlias,
		f: func() error {
			if !params.Enabled() {
				defer func() { done <- struct{}{} }()
			} else {
				// mutex is needed because it's handled in the queue
				info := getInfo(vos.VM)
				info.mutex.Lock()
				defer info.mutex.Unlock()
			}

			return unprepareProgress(t, vos.VM, params.Destroy)
		},
	}

	// start preparing
	if !params.Enabled() {
		<-done
		return true, err
	}

	return true, nil

}

func unprepareProgress(t tracer.Tracer, vm *virt.VM, destroy bool) error {
	if err := vm.Unprepare(t, destroy); err != nil {
		return err
	}

	// we'll wait indefinitely (up to 24 hours) for the VM state to actually be
	// "STOPPED" before we set the hostKite to nil.
	if err := vm.WaitForState("STOPPED", time.Hour*24); err != nil {
		return err
	}

	if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
	}); err != nil {
		return fmt.Errorf("unprepareProgress hostKite nil setting: %v", err)
	}

	if _, err := checkAndUpdateState(vm.Id, vm.State); err != nil {
		return err
	}

	return nil
}

func prepareProgress(t tracer.Tracer, vm *virt.VM) error {
	if err := vm.Prepare(t, false); err != nil {
		return err
	}

	if _, err := checkAndUpdateState(vm.Id, vm.State); err != nil {
		return err
	}

	return nil
}

func prepareHome(vos *virt.VOS) error {
	rootVos, err := vos.VM.OS(&virt.RootUser)
	if err != nil {
		return err
	}

	vmWebDir := "/home/" + vos.VM.WebHome + "/Web"
	userWebDir := "/home/" + vos.User.Name + "/Web"

	vmWebVos := rootVos
	if vmWebDir == userWebDir {
		vmWebVos = vos
	}

	rootVos.Chmod("/", 0755)     // make sure that executable flag is set
	rootVos.Chmod("/home", 0755) // make sure that executable flag is set

	if err := createUserHome(vos.User, rootVos, vos); err != nil {
		return err
	}

	if err := createVmWebDir(vos.VM, vmWebDir, rootVos, vmWebVos); err != nil {
		return err
	}

	if vmWebDir == userWebDir {
		return nil
	}

	if err = createUserWebDir(vos.User, vmWebDir, userWebDir, rootVos, vos); err != nil {
		return err
	}

	return nil
}

func createUserHome(user *virt.User, rootVos, userVos *virt.VOS) error {
	if info, err := rootVos.Stat("/home/" + user.Name); err == nil {
		rootVos.Chmod("/home/"+user.Name, info.Mode().Perm()|0511) // make sure that user read and executable flag is set
		return nil
	}
	// home directory does not yet exist

	if _, err := rootVos.Stat("/home/" + user.OldName); user.OldName != "" && err == nil {
		if err := rootVos.Rename("/home/"+user.OldName, "/home/"+user.Name); err != nil {
			return err
		}
		if err := rootVos.Symlink(user.Name, "/home/"+user.OldName); err != nil {
			return err
		}
		if err := rootVos.Chown("/home/"+user.OldName, user.Uid, user.Uid); err != nil {
			return err
		}

		if target, err := rootVos.Readlink("/var/www"); err == nil && target == "/home/"+user.OldName+"/Web" {
			if err := rootVos.Remove("/var/www"); err != nil {
				return err
			}
			if err := rootVos.Symlink("/home/"+user.Name+"/Web", "/var/www"); err != nil {
				return err
			}
		}

		ldapserver.ClearCache()
		return nil
	}

	if err := rootVos.MkdirAll("/home/"+user.Name, 0755); err != nil && !os.IsExist(err) {
		return err
	}
	if err := rootVos.Chown("/home/"+user.Name, user.Uid, user.Uid); err != nil {
		return err
	}
	if err := copyIntoVos(templateDir+"/user", "/home/"+user.Name, userVos); err != nil {
		return err
	}

	return nil
}

func createVmWebDir(vm *virt.VM, vmWebDir string, rootVos, vmWebVos *virt.VOS) error {
	if err := rootVos.Symlink(vmWebDir, "/var/www"); err != nil {
		if !os.IsExist(err) {
			return err
		}
		return nil
	}
	// symlink successfully created

	if _, err := rootVos.Stat(vmWebDir); err == nil {
		return nil
	}
	// vmWebDir directory does not yet exist

	// migration of old Sites directory
	migrationErr := vmWebVos.Rename("/home/"+vm.WebHome+"/Sites/"+vm.HostnameAlias, vmWebDir)
	vmWebVos.Remove("/home/" + vm.WebHome + "/Sites")
	rootVos.Remove("/etc/apache2/sites-enabled/" + vm.HostnameAlias)

	if migrationErr != nil {
		// create fresh Web directory if migration unsuccessful
		if err := vmWebVos.MkdirAll(vmWebDir, 0755); err != nil {
			return err
		}
		if err := copyIntoVos(templateDir+"/website", vmWebDir, vmWebVos); err != nil {
			return err
		}
	}

	return nil
}

func createUserWebDir(user *virt.User, vmWebDir, userWebDir string, rootVos, userVos *virt.VOS) error {
	if _, err := rootVos.Stat(userWebDir); err == nil {
		return nil
	}
	// userWebDir directory does not yet exist

	if err := userVos.MkdirAll(userWebDir, 0755); err != nil {
		return err
	}
	if err := copyIntoVos(templateDir+"/website", userWebDir, userVos); err != nil {
		return err
	}
	if err := rootVos.Symlink(userWebDir, vmWebDir+"/~"+user.Name); err != nil && !os.IsExist(err) {
		return err
	}

	return nil
}

func copyIntoVos(src, dst string, vos *virt.VOS) error {
	sf, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return err
	}

	if fi.Name() == "empty-directory" {
		// ignored file
	} else if fi.IsDir() {
		if err := vos.Mkdir(dst, fi.Mode()); err != nil && !os.IsExist(err) {
			return err
		}

		entries, err := sf.Readdirnames(0)
		if err != nil {
			return err
		}
		for _, entry := range entries {
			if err := copyIntoVos(src+"/"+entry, dst+"/"+entry, vos); err != nil {
				return err
			}
		}
	} else {
		df, err := vos.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
		if err != nil {
			return err
		}
		defer df.Close()

		if _, err := io.Copy(df, sf); err != nil {
			return err
		}
	}

	return nil
}
