// +build linux

package oskite

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"koding/oskite/ldapserver"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os"
	"os/exec"
	"syscall"
	"time"

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

func vmUnprepareOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmUnprepare(vos)
}

func vmStopOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmStop(vos)
}

func vmReinitializeOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmReinitialize(vos)
}

func vmPrepareOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmPrepare(vos)
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
	return vmUsage(vos)
}

func spawnFuncOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var command []string

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&command) != nil {
		return nil, &kite.ArgumentError{Expected: "[array of strings]"}
	}

	return spawnFunc(command, vos)
}

func execFuncOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var line string
	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&line) != nil {
		return nil, &kite.ArgumentError{Expected: "[string]"}
	}

	return execFunc(line, vos)
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

func execFunc(line string, vos *virt.VOS) (interface{}, error) {
	return newOutput(vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line))
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
			if lastError = vos.VM.WaitForNetwork(time.Second * 5); lastError != nil {
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

			return fmt.Sprintf("vm.Shutdown %s", vos.VM.HostnameAlias), nil
		},
	}

	<-done

	if lastError != nil {
		return nil, lastError
	}

	return true, nil
}

func vmUnprepare(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	var lastError error
	done := make(chan struct{}, 1)
	prepareQueue <- &QueueJob{
		msg: "vm.Unprepare" + vos.VM.HostnameAlias,
		f: func() (string, error) {
			defer func() { done <- struct{}{} }()

			if lastError = vos.VM.Shutdown(); lastError != nil {
				return "", lastError
			}

			for step := range vos.VM.Unprepare() {
				lastError = step.Err
			}

			if lastError != nil {
				return "", lastError
			}

			return fmt.Sprintf("vm.Unprepare %s", vos.VM.HostnameAlias), nil
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

	return true, vos.VM.ResizeRBD()
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

func vmPrepare(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	prepared, err := isVmPrepared(vos.VM)
	if err != nil {
		return nil, err
	}

	if prepared {
		return nil, ErrVmAlreadyPrepared
	}

	for _ = range vos.VM.Prepare(false) {
	}

	return true, nil
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

	for _ = range vos.VM.Prepare(true) {
	}

	if err := vos.VM.Start(); err != nil {
		return nil, err
	}

	return true, nil
}

func startAndPrepareVM(vm *virt.VM) error {
	prepared, err := isVmPrepared(vm)
	if err != nil {
		return err
	}

	if prepared {
		return nil
	}

	var lastError error
	done := make(chan struct{}, 1)
	prepareQueue <- &QueueJob{
		msg: "vm prepare and start " + vm.HostnameAlias,
		f: func() (string, error) {
			defer func() { done <- struct{}{} }()

			startTime := time.Now()

			// prepare first
			for step := range vm.Prepare(false) {
				lastError = step.Err
				if lastError != nil {
					return "", fmt.Errorf("preparing VM %s", lastError)
				}
			}

			// start it
			if err := vm.Start(); err != nil {
				log.LogError(err, 0)
			}

			// wait until network is up
			if err := vm.WaitForNetwork(time.Second * 5); err != nil {
				log.Error("%v", err)
			}

			res := fmt.Sprintf("VM PREPARE and START: %s [%s] - ElapsedTime: %.10f seconds.",
				vm, vm.HostnameAlias, time.Since(startTime).Seconds())

			return res, nil
		},
	}

	log.Info("putting %s into queue. total vms in queue: %d of %d",
		vm.HostnameAlias, currentQueueCount.Get(), len(prepareQueue))

	// wait until the prepareWorker has picked us and we finished
	// to return something to the client
	<-done

	return lastError
}

type progresser interface {
	Enabled() bool
	Call(v interface{})
}

type progressParamsOld struct {
	OnProgress dnode.Callback
}

func (p *progressParamsOld) Enabled() bool      { return p.OnProgress != nil }
func (p *progressParamsOld) Call(v interface{}) { p.OnProgress(v) }

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

func vmPrepareAndStart(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	params := new(progressParamsOld)
	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	return progress(vos, "vm.prepareAndStart"+vos.VM.HostnameAlias, params, func() error {
		for step := range prepareProgress(vos) {
			if params.OnProgress != nil {
				params.OnProgress(step)
			}

			if step.Err != nil {
				return step.Err
			}
		}

		return nil
	})
}

func vmDestroyOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	params := new(progressParamsOld)
	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	return progress(vos, "vm.destroy"+vos.VM.HostnameAlias, params, func() error {
		var lastError error
		for step := range unprepareProgress(vos, true) {
			if params.OnProgress != nil {
				params.OnProgress(step)
			}

			if step.Err != nil {
				lastError = step.Err
			}
		}

		return lastError
	})

	return true, nil
}

func vmStopAndUnprepare(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	params := new(progressParamsOld)
	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	return progress(vos, "vm.stopAndUnprepare"+vos.VM.HostnameAlias, params, func() error {
		var lastError error
		for step := range unprepareProgress(vos, false) {
			if params.OnProgress != nil {
				params.OnProgress(step)
			}

			if step.Err != nil {
				lastError = step.Err
			}
		}

		return lastError
	})
}

func unprepareProgress(vos *virt.VOS, destroy bool) <-chan *virt.Step {
	results := make(chan *virt.Step)

	go func() {
		var lastError error
		var prepared bool

		defer func() {
			if lastError != nil {
				lastError = kite.NewKiteErr(lastError)
			}

			results <- &virt.Step{Err: lastError, Message: "FINISHED"}
			close(results)
		}()

		prepared, lastError = isVmPrepared(vos.VM)
		if lastError != nil {
			return
		}

		if !prepared {
			results <- &virt.Step{Message: "Vm is already unprepared"}
			return
		}

		start := time.Now()
		if lastError = vos.VM.Shutdown(); lastError != nil {
			return
		}

		// now start our unprepare progress. Also this enables to get the total
		// steps before we send the result of shutdown back
		unprepareChan := vos.VM.Unprepare()

		totalStep := cap(unprepareChan) + 1 // include vm.Shutdown()
		if destroy {
			totalStep += 1 // include vm.Destroy()
		}

		results <- &virt.Step{
			Message:     "VM is stopped.",
			ElapsedTime: time.Since(start).Seconds(),
			CurrentStep: 1,
			TotalStep:   totalStep,
		}

		var lastCurrentStep int
		for step := range unprepareChan {
			lastError = step.Err

			// add +1 because of previous vm.Shutdown()
			step.CurrentStep += 1
			step.TotalStep = totalStep

			lastCurrentStep = step.CurrentStep

			// send every process back to the client
			results <- step
		}

		if destroy {
			start := time.Now()
			if lastError = vos.VM.Destroy(); lastError != nil {
				return
			}

			results <- &virt.Step{
				Message:     "VM is destroyed.",
				ElapsedTime: time.Since(start).Seconds(),
				CurrentStep: lastCurrentStep + 1,
				TotalStep:   totalStep,
			}

			// TODO: enable this after getting the relationships to be removed.
			// query := func(c *mgo.Collection) error {
			// 	return c.Remove(bson.M{"hostnameAlias": vos.VM.HostnameAlias})
			// }

			// if err := mongodbConn.Run("jVMs", query); err != nil {
			// 	return nil, err
			// }

		}
	}()

	return results
}

func prepareProgress(vos *virt.VOS) <-chan *virt.Step {
	results := make(chan *virt.Step)

	go func() {
		var lastError error
		defer func() {
			if lastError != nil {
				lastError = kite.NewKiteErr(lastError)
			}

			results <- &virt.Step{Err: lastError, Message: "FINISHED"}
			close(results)
		}()

		var prepared bool
		prepared, lastError = isVmPrepared(vos.VM)
		if lastError != nil {
			return
		}

		var totalStep int = 2 // vm.Start and vm.WaitForNetwork

		if !prepared {
			for step := range vos.VM.Prepare(false) {
				lastError = step.Err
				if lastError != nil {
					lastError = fmt.Errorf("preparing VM %s", lastError)
					return
				}

				// add VM.Start() and Vm.WaitForNetwork() steps too
				totalStep = step.TotalStep + 2
				step.TotalStep = totalStep

				// send every process back to the client
				results <- step
			}
		}

		// start vm and return any error
		start := time.Now()
		if lastError = vos.VM.Start(); lastError != nil {
			return
		}
		results <- &virt.Step{
			Message:     "VM is started.",
			ElapsedTime: time.Since(start).Seconds(),
			CurrentStep: totalStep - 1,
			TotalStep:   totalStep,
		}

		// wait until network is up
		start = time.Now()
		if lastError = vos.VM.WaitForNetwork(time.Second * 5); lastError != nil {
			return
		}
		results <- &virt.Step{
			Message:     "VM network is ready and up",
			ElapsedTime: time.Since(start).Seconds(),
			CurrentStep: totalStep,
			TotalStep:   totalStep,
		}

		var rootVos *virt.VOS
		rootVos, lastError = vos.VM.OS(&virt.RootUser)
		if lastError != nil {
			return
		}

		vmWebDir := "/home/" + vos.VM.WebHome + "/Web"
		userWebDir := "/home/" + vos.User.Name + "/Web"

		vmWebVos := rootVos
		if vmWebDir == userWebDir {
			vmWebVos = vos
		}

		rootVos.Chmod("/", 0755)     // make sure that executable flag is set
		rootVos.Chmod("/home", 0755) // make sure that executable flag is set

		if lastError = createUserHome(vos.User, rootVos, vos); lastError != nil {
			return
		}

		if lastError = createVmWebDir(vos.VM, vmWebDir, rootVos, vmWebVos); lastError != nil {
			return
		}

		if vmWebDir == userWebDir {
			return
		}

		if lastError = createUserWebDir(vos.User, vmWebDir, userWebDir, rootVos, vos); lastError != nil {
			return
		}
	}()

	return results

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
