package main

import (
	"errors"
	kitelib "kite"
	"koding/tools/kite"
	"koding/virt"
)

func vmStartNewKite(r *kitelib.Request) (interface{}, error) {
	var params struct {
		// might be vm ID or hostnameAlias
		CorrelationName string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.CorrelationName == "" {
		return nil, errors.New("{ correlationName: [string]}")
	}

	vos, err := getVos(r.Username, params.CorrelationName)
	if err != nil {
		return nil, err
	}

	return vmStart(vos)
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
