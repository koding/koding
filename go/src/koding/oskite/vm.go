// +build linux

package oskite

import (
	"errors"
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os"
	"time"

	"labix.org/v2/mgo/bson"
)

var ErrVmAlreadyPrepared = errors.New("vm is already prepared")

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

func vmStart(vos *virt.VOS) (interface{}, error) {
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
		return true, lastError
	}

	return true, nil
}

func vmShutdown(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	done := make(chan struct{}, 1)
	prepareQueue <- &QueueJob{
		msg: "vm.Shutdown" + vos.VM.HostnameAlias,
		f: func() (string, error) {
			defer func() { done <- struct{}{} }()

			if err := vos.VM.Shutdown(); err != nil {
				return "", err
			}

			return fmt.Sprintf("vm.Shutdown %s", vos.VM.HostnameAlias), nil
		},
	}

	<-done
	return true, nil
}

func vmUnprepare(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	done := make(chan struct{}, 1)
	prepareQueue <- &QueueJob{
		msg: "vm.Unprepare" + vos.VM.HostnameAlias,
		f: func() (string, error) {
			defer func() { done <- struct{}{} }()

			if err := vos.VM.Shutdown(); err != nil {
				return "", err
			}

			var err error
			for step := range vos.VM.Unprepare() {
				err = step.Err
			}
			if err != nil {
				return "", err
			}

			return fmt.Sprintf("vm.Unprepare %s", vos.VM.HostnameAlias), nil
		},
	}

	<-done

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

func execFunc(line string, vos *virt.VOS) (interface{}, error) {
	return vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line).CombinedOutput()
}

func spawnFunc(command []string, vos *virt.VOS) (interface{}, error) {
	return vos.VM.AttachCommand(vos.User.Uid, "", command...).CombinedOutput()
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

func vmPrepareAndStart(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		OnProgress dnode.Callback
	}

	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	var lastError error
	done := make(chan struct{}, 1)

	if params.OnProgress != nil {
		params.OnProgress(&virt.Step{Message: "STARTED"})
		done = nil // not used anymore
	}

	go func() {
		prepareQueue <- &QueueJob{
			msg: "vm.prepareAndStart" + vos.VM.HostnameAlias,
			f: func() (string, error) {
				if params.OnProgress == nil {
					defer func() { done <- struct{}{} }()
				} else {
					// mutex is needed because it's handled in the queue
					info := getInfo(vos.VM)
					info.mutex.Lock()
					defer info.mutex.Unlock()
				}

				for step := range prepareProgress(vos) {
					if params.OnProgress != nil {
						params.OnProgress(step)
					}

					if step.Err != nil {
						lastError = step.Err
						return "", lastError
					}
				}

				return fmt.Sprintf("vm.prepareAndStart %s", vos.VM.HostnameAlias), nil
			},
		}
	}()

	if params.OnProgress == nil {
		// wait until the prepareWorker has picked us and we finished
		// to return something to the client
		<-done
		if lastError != nil {
			return true, lastError
		}
	}

	return true, nil
}

func vmStopAndUnprepare(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		OnProgress dnode.Callback
	}

	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	var lastError error
	done := make(chan struct{}, 1)

	if params.OnProgress != nil {
		params.OnProgress(&virt.Step{Message: "STARTED"})
		done = nil // not used anymore
	}

	go func() {
		prepareQueue <- &QueueJob{
			msg: "vm.StopAndUnprepare" + vos.VM.HostnameAlias,
			f: func() (string, error) {
				if params.OnProgress == nil {
					defer func() { done <- struct{}{} }()
				} else {
					// mutex is needed because it's handled in the queue
					info := getInfo(vos.VM)
					info.mutex.Lock()
					defer info.mutex.Unlock()
				}

				for step := range unprepareProgress(vos) {
					if params.OnProgress != nil {
						params.OnProgress(step)
					}

					if step.Err != nil {
						lastError = step.Err
						return "", lastError
					}
				}

				return fmt.Sprintf("vm.StopAndUnprepare %s", vos.VM.HostnameAlias), nil
			},
		}
	}()

	if params.OnProgress == nil {
		// wait until the prepareWorker has picked us and we finished
		// to return something to the client
		<-done
		if lastError != nil {
			return true, lastError
		}
	}

	return true, nil
}

func unprepareProgress(vos *virt.VOS) <-chan *virt.Step {
	results := make(chan *virt.Step)

	go func() {
		var lastError error
		defer func() {
			results <- &virt.Step{Err: lastError, Message: "FINISHED"}
			close(results)
		}()

		var prepared bool
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
		results <- &virt.Step{
			Message:     "VM is stopped.",
			ElapsedTime: time.Since(start).Seconds(),
			CurrentStep: 1,
			TotalStep:   6, // hardcoded I know, 5 comes from vm.Unprepare()
		}

		for step := range vos.VM.Unprepare() {
			lastError = step.Err

			// add +1 because of previous vm.Shutdown()
			step.CurrentStep = step.CurrentStep + 1
			step.TotalStep = step.TotalStep + 1

			// send every process back to the client
			results <- step
		}
	}()

	return results
}

func prepareProgress(vos *virt.VOS) <-chan *virt.Step {
	results := make(chan *virt.Step)

	go func() {
		var lastError error
		defer func() {
			results <- &virt.Step{Err: lastError, Message: "FINISHED"}
			close(results)
		}()

		var prepared bool
		prepared, lastError = isVmPrepared(vos.VM)
		if lastError != nil {
			return
		}

		if prepared {
			results <- &virt.Step{Message: "Vm is already prepared"}
			return
		}

		var totalStep int
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
		createUserHome(vos.User, rootVos, vos)
		createVmWebDir(vos.VM, vmWebDir, rootVos, vmWebVos)
		if vmWebDir != userWebDir {
			createUserWebDir(vos.User, vmWebDir, userWebDir, rootVos, vos)
		}
	}()

	return results

}
