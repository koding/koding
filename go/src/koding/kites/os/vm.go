// +build linux

package main

import (
	"errors"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os"

	"labix.org/v2/mgo/bson"
)

var ErrVmAlreadyPrepared = errors.New("vm is already prepared")

func vmStartOldKite(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmStart(vos)
}

func vmShutdown(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}
	if err := vos.VM.Shutdown(); err != nil {
		panic(err)
	}
	return true, nil
}

func vmUnprepare(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	if err := vos.VM.Unprepare(); err != nil {
		return nil, err
	}

	return true, nil
}

func vmStop(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}
	if err := vos.VM.Stop(); err != nil {
		panic(err)
	}
	return true, nil
}

func vmReinitialize(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}
	vos.VM.Prepare(true, log.Warning)
	if err := vos.VM.Start(); err != nil {
		panic(err)
	}
	return true, nil
}

func vmPrepare(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
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

	if !isPrepared {
		vos.VM.Prepare(false, log.Warning)
		return true, nil
	} else {
		return false, ErrVmAlreadyPrepared
	}
}

func vmInfo(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	info := channel.KiteData.(*VMInfo)
	info.State = vos.VM.GetState()
	return info, nil
}

func vmResizeDisk(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}
	return true, vos.VM.ResizeRBD()
}

func vmCreateSnaphost(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	snippetId := bson.NewObjectId().Hex()
	if err := vos.VM.CreateConsistentSnapshot(snippetId); err != nil {
		return nil, err
	}

	return snippetId, nil
}

func spawn(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var command []string
	if args.Unmarshal(&command) != nil {
		return nil, &kite.ArgumentError{Expected: "[array of strings]"}
	}
	return vos.VM.AttachCommand(vos.User.Uid, "", command...).CombinedOutput()
}

func exec(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var line string
	if args.Unmarshal(&line) != nil {
		return nil, &kite.ArgumentError{Expected: "[string]"}
	}
	return vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line).CombinedOutput()
}
