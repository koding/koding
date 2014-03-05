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
	return vmInfo(vos, c)
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

	done := make(chan struct{}, 1)
	prepareQueue <- &QueueJob{
		msg: "vm.Start" + vos.VM.HostnameAlias,
		f: func() string {
			if err := vos.VM.Start(); err != nil {
				panic(err)
			}

			// wait until network is up
			if err := vos.VM.WaitForNetwork(time.Second * 5); err != nil {
				panic(err)
			}

			done <- struct{}{}
			return fmt.Sprintf("vm.Start %s", vos.VM.HostnameAlias)
		},
	}

	<-done

	return true, nil
}

func vmShutdown(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	done := make(chan struct{}, 1)
	prepareQueue <- &QueueJob{
		msg: "vm.Shutdown" + vos.VM.HostnameAlias,
		f: func() string {

			if err := vos.VM.Shutdown(); err != nil {
				panic(err)
			}

			done <- struct{}{}
			return fmt.Sprintf("vm.Shutdown %s", vos.VM.HostnameAlias)
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

func vmInfo(vos *virt.VOS, channel *kite.Channel) (interface{}, error) {
	info := channel.KiteData.(*VMInfo)
	info.State = vos.VM.GetState()
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

	vos.VM.Prepare(false)
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

	vos.VM.Prepare(true)
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
