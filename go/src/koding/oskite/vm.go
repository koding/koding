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

	var lastError error

	done := make(chan struct{}, 1)
	prepareQueue <- &QueueJob{
		msg: "vm.Start" + vos.VM.HostnameAlias,
		f: func() (string, error) {
			defer func() { done <- struct{}{} }()

			if lastError = vos.VM.Start(); lastError != nil {
				return "", lastError
			}

			// wait until network is up
			if lastError = vos.VM.WaitForNetwork(); lastError != nil {
				return "", lastError
			}

			if lastError = updateState(vos.VM); lastError != nil {
				return "", lastError
			}

			return fmt.Sprintf("vm.Start %s", vos.VM.HostnameAlias), nil
		},
	}

	<-done

	if lastError != nil {
		return nil, lastError
	}

	return true, nil
}

func vmShutdown(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	var lastError error
	done := make(chan struct{}, 1)
	prepareQueue <- &QueueJob{
		msg: "vm.Shutdown" + vos.VM.HostnameAlias,
		f: func() (string, error) {
			defer func() { done <- struct{}{} }()

			if lastError = vos.VM.Shutdown(); lastError != nil {
				return "", lastError
			}

			if lastError = updateState(vos.VM); lastError != nil {
				return "", lastError
			}

			return fmt.Sprintf("vm.Shutdown %s", vos.VM.HostnameAlias), nil
		},
	}

	<-done

	if lastError != nil {
		return nil, lastError
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

	if err := updateState(vos.VM); err != nil {
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
	info.State = vos.VM.GetState()
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

// progress is function that enables sync and async call of the given function
// "f". We pass an interface called progresser just for compatibility of
// newkite and oldkite (they each have different callback signatures)
// TODO: fix this function signature, a function shouldn't have this much arguments.
func progress(vos *virt.VOS, desc string, p progresser, f func() error) (interface{}, error) {
	var lastError error
	done := make(chan struct{}, 1)

	if p.Enabled() {
		p.Call(&virt.Step{Message: "STARTED"})
		done = nil // not used anymore
	}

	go func() {
		prepareQueue <- &QueueJob{
			msg: desc,
			f: func() (string, error) {
				if !p.Enabled() {
					defer func() { done <- struct{}{} }()
				} else {
					// mutex is needed because it's handled in the queue
					info := getInfo(vos.VM)
					info.mutex.Lock()
					defer info.mutex.Unlock()
				}

				if err := f(); err != nil {
					lastError = err
					return "", err
				}

				return desc, nil
			},
		}
	}()

	if !p.Enabled() {
		// wait until the prepareWorker has picked us and we finished
		// to return something to the client
		<-done
		if lastError != nil {
			return true, lastError
		}
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

	usage, err := totalUsage(vos, params.GroupId)
	if err != nil {
		log.Info("usage -1 [%s] err: %v", vos.VM.HostnameAlias, err)
		return nil, errors.New("usage couldn't be retrieved. please consult to support [1].")
	}

	limits, err := usage.prepareLimits(channel.Username, params.GroupId)
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

	// start preparing
	if params.Enabled() {
		go prepareProgress(params, vos)
		return true, nil
	}

	if err := prepareProgress(nil, vos); err != nil {
		return nil, err
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

	if params.Enabled() {
		go unprepareProgress(params, vos, params.Destroy)
		return true, nil
	}

	if err := unprepareProgress(nil, vos, params.Destroy); err != nil {
		return nil, err
	}

	return true, nil
}

func unprepareProgress(t tracer.Tracer, vos *virt.VOS, destroy bool) (err error) {
	defer func() {
		if err != nil {
			err = kite.NewKiteErr(err)
		}

		t.Trace(tracer.Message{Err: err, Message: "FINISHED"})
	}()

	t.Trace(tracer.Message{Message: "STARTED"})

	// unprepare
	err = vos.VM.Unprepare(t, destroy)

	if err = mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": vos.VM.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
	}); err != nil {
		return fmt.Errorf("unprepareProgress hostKite nil setting: %v", err)
	}

	// mark it as stopped in mongodb
	if err := updateState(vos.VM); err != nil {
		return err
	}

	return nil
}

func prepareProgress(t tracer.Tracer, vos *virt.VOS) (err error) {
	defer func() {
		if err != nil {
			err = kite.NewKiteErr(err)
		}
	}()

	err = vos.VM.Prepare(t, false)
	if err != nil {
		return err
	}

	// it's now running
	if err := updateState(vos.VM); err != nil {
		return err
	}

	err = prepareHome(vos)
	if err != nil {
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
