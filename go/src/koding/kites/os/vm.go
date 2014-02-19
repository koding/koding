// +build linux

package main

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

func spawnOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var command []string
	if args.Unmarshal(&command) != nil {
		return nil, &kite.ArgumentError{Expected: "[array of strings]"}
	}

	return spawn(command, vos)
}

func execOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var line string
	if args.Unmarshal(&line) != nil {
		return nil, &kite.ArgumentError{Expected: "[string]"}
	}

	return exec(line, vos)
}

//////////////////////////////

func exec(line string, vos *virt.VOS) (interface{}, error) {
	return vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line).CombinedOutput()
}

func spawn(command []string, vos *virt.VOS) (interface{}, error) {
	return vos.VM.AttachCommand(vos.User.Uid, "", command...).CombinedOutput()
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

	isPrepared := true
	if _, err := os.Stat(vos.VM.File("rootfs/dev")); err != nil {
		if !os.IsNotExist(err) {
			return nil, err
		}

		isPrepared = false
	}

	if isPrepared {
		return false, ErrVmAlreadyPrepared
	}

	// TODO, change that it returns an error
	vos.VM.Prepare(false, log.Warning)
	return true, nil
}

func vmReinitialize(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	vos.VM.Prepare(true, log.Warning)
	if err := vos.VM.Start(); err != nil {
		return nil, err
	}

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

func vmShutdown(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	if err := vos.VM.Shutdown(); err != nil {
		return nil, err
	}

	return true, nil
}

func vmStart(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	if err := startAndPrepareVM(vos.VM, nil); err != nil {
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

	// send true if vm is ready
	return true, nil
}

func startAndPrepareVM(vm *virt.VM, channel *kite.Channel) error {
	err := validateVM(vm)
	if err != nil {
		return err
	}

	var info *VMInfo

	if info == nil {
		infosMutex.Lock()
		var found bool
		info, found = infos[vm.Id]
		if !found {
			info = newInfo(vm)
			infos[vm.Id] = info
		}

		if channel != nil {
			info.useCounter += 1
			info.timeout.Stop()

			channel.KiteData = info
			channel.OnDisconnect(func() {
				info.mutex.Lock()
				defer info.mutex.Unlock()

				info.useCounter -= 1
				info.startTimeout()
			})
		}

		infosMutex.Unlock()
	}

	info.vm = vm
	info.mutex.Lock()
	defer info.mutex.Unlock()

	isPrepared := true
	if _, err := os.Stat(vm.File("rootfs/dev")); err != nil {
		if !os.IsNotExist(err) {
			panic(err)
		}
		isPrepared = false
	}

	if !isPrepared || info.currentHostname != vm.HostnameAlias {
		log.Info("putting %s into queue. total vms in queue: %d of %d",
			vm.HostnameAlias, len(prepareQueue), prepareQueueLimit)

		wait := make(chan struct{}, 0)
		prepareQueue <- func(done chan string) {
			startTime := time.Now()

			vm.Prepare(false, log.Warning)

			res := fmt.Sprintf("VM PREPARE and START: %s [%s] - ElapsedTime: %.10f seconds.\n",
				vm, vm.HostnameAlias, time.Since(startTime).Seconds())

			done <- res
			wait <- struct{}{}
		}

		// wait until the prepareWorker has picked us and we finished
		<-wait
	}

	// if it's started already it will not do anything
	if err := vm.Start(); err != nil {
		log.LogError(err, 0)
	}

	// wait until network is up
	if err := vm.WaitForNetwork(time.Second * 5); err != nil {
		log.Error("%v", err)
	}

	info.currentHostname = vm.HostnameAlias
	return nil
}

// prepareWorker listens from prepareQueue channel and runs the functions it receives
func prepareWorker() {
	for fn := range prepareQueue {
		done := make(chan string, 1)
		go fn(done)

		select {
		case vmRes := <-done:
			log.Info("done preparing vm %s", vmRes)
		case <-time.After(time.Second * 20):
			log.Error("timing out preparing vm")
		}
	}
}
