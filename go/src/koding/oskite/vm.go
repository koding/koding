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
	if args.Unmarshal(&command) != nil {
		return nil, &kite.ArgumentError{Expected: "[array of strings]"}
	}

	return spawnFunc(command, vos)
}

func execFuncOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var line string
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

	if err := startAndPrepareVM(vos.VM); err != nil {
		return nil, err
	}

	rootVos, err := vos.VM.OS(&virt.RootUser)
	if err != nil {
		return nil, err
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

	if err := vos.VM.Unprepare(); err != nil {
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
	var info *VMInfo
	var ok bool

	info, ok = infos[vos.VM.Id]
	if !ok {
		info = newInfo(vos.VM)
		info.State = vos.VM.GetState()
		infos[vos.VM.Id] = info
	} else {
		info.State = vos.VM.GetState()
	}

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

func vmStartProgress(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		OnProgress dnode.Callback
	}

	if args.Unmarshal(&params) != nil || params.OnProgress == nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	params.OnProgress(&virt.PrepareStep{
		Err:         nil,
		CurrentStep: 0,
		TotalStep:   0,
		Message:     "vmPrepareAndStart called.",
		TotalTime:   0,
	})

	go func() {
		prepareQueue <- &QueueJob{
			msg: "vm.Start" + channel.CorrelationName,
			f: func() (string, error) {
				var lastError error

				defer func() {
					params.OnProgress(&virt.PrepareStep{
						Err:       lastError,
						Message:   "FINISHED",
						TotalTime: 0,
					})
				}()

				var prepared bool
				prepared, lastError = isVmPrepared(vos.VM)
				if lastError != nil {
					return "", lastError
				}

				if prepared {
					return "vm already repared", nil
				}

				for step := range vos.VM.Prepare(false) {
					lastError = step.Err
					if lastError != nil {
						return "", fmt.Errorf("preparing VM %s", lastError)
					}

					params.OnProgress(step) // send every process back to the client
				}

				// start vm and return any error
				start := time.Now()
				if lastError = vos.VM.Start(); lastError != nil {
					return "", fmt.Errorf("starting VM %s", lastError)
				}

				params.OnProgress(&virt.PrepareStep{
					Err:       nil,
					Message:   "VM is started.",
					TotalTime: time.Since(start).Seconds(),
				})

				// wait until network is up
				start = time.Now()
				if lastError = vos.VM.WaitForNetwork(time.Second * 5); lastError != nil {
					return "", fmt.Errorf("waiting for network VM %s", lastError)
				}

				params.OnProgress(&virt.PrepareStep{
					Err:       nil,
					Message:   "VM network is ready and up.",
					TotalTime: time.Since(start).Seconds(),
				})

				var rootVos *virt.VOS
				rootVos, lastError = vos.VM.OS(&virt.RootUser)
				if lastError != nil {
					return "", lastError
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

				return fmt.Sprintf("vm.PrepareAndStart %s", channel.CorrelationName), nil
			},
		}
	}()

	return true, nil
}
