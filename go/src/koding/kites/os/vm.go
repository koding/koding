// +build linux

package main

import (
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"time"

	"labix.org/v2/mgo/bson"
)

func registerVmMethods(k *kite.Kite) {
	registerVmMethod(k, "vm.start", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		if err := vos.VM.Start(); err != nil {
			panic(err)
		}

		// wait until network is up
		if err := vos.VM.WaitForNetwork(time.Second * 5); err != nil {
			panic(err)
		}

		return true, nil
	})

	registerVmMethod(k, "vm.shutdown", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		if err := vos.VM.Shutdown(); err != nil {
			panic(err)
		}
		return true, nil
	})

	registerVmMethod(k, "vm.unprepare", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}

		if err := vos.VM.Unprepare(); err != nil {
			return nil, err
		}

		return true, nil
	})

	registerVmMethod(k, "vm.stop", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		if err := vos.VM.Stop(); err != nil {
			panic(err)
		}
		return true, nil
	})

	registerVmMethod(k, "vm.reinitialize", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		vos.VM.Prepare(true, log.Warning)
		if err := vos.VM.Start(); err != nil {
			panic(err)
		}
		return true, nil
	})

	registerVmMethod(k, "vm.info", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		info := channel.KiteData.(*VMInfo)
		info.State = vos.VM.GetState()
		return info, nil
	})

	registerVmMethod(k, "vm.resizeDisk", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}
		return true, vos.VM.ResizeRBD()
	})

	registerVmMethod(k, "vm.createSnapshot", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		if !vos.Permissions.Sudo {
			return nil, &kite.PermissionError{}
		}

		snippetId := bson.NewObjectId().Hex()
		if err := vos.VM.CreateConsistentSnapshot(snippetId); err != nil {
			return nil, err
		}

		return snippetId, nil
	})

	registerVmMethod(k, "spawn", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var command []string
		if args.Unmarshal(&command) != nil {
			return nil, &kite.ArgumentError{Expected: "[array of strings]"}
		}
		return vos.VM.AttachCommand(vos.User.Uid, "", command...).CombinedOutput()
	})

	registerVmMethod(k, "exec", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var line string
		if args.Unmarshal(&line) != nil {
			return nil, &kite.ArgumentError{Expected: "[string]"}
		}
		return vos.VM.AttachCommand(vos.User.Uid, "", "/bin/bash", "-c", line).CombinedOutput()
	})

}
