// +build linux

package main

import (
	"errors"
	kitelib "kite"
	"koding/tools/kite"
	"koding/virt"
)

// vosFunc is used to associate each request with a VOS instance.
type vosFunc func(*kitelib.Request, *virt.VOS) (interface{}, error)

// vosMethod is compat wrapper around the new kite library. It's basically
// creates a vos instance that is the plugged into the the base functions.
func vosMethod(k *kitelib.Kite, method string, vosFn vosFunc) {
	handler := func(r *kitelib.Request) (interface{}, error) {
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

		return vosFn(r, vos)
	}

	k.HandleFunc(method, handler)
}

func vmStartNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmStart(vos)
}

func vmStopNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmStop(vos)
}

func vmShutdownNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmShutdown(vos)
}

func vmUnprepareNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmUnprepare(vos)
}

func vmReinitializeNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmReinitialize(vos)
}

func vmInfoNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmInfo(vos)
}

func vmPrepareNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmPrepare(vos)
}

func vmResizeDiskNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmResizeDisk(vos)
}

func vmCreateSnapshotNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmCreateSnapshot(vos)
}

func spawnNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Command []string
	}

	if r.Args.One().Unmarshal(&params) != nil || len(params.Command) == 0 {
		return nil, &kite.ArgumentError{Expected: "[array of strings]"}
	}

	return spawn(params.Command, vos)
}

func execNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Line string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Line == "" {
		return nil, &kite.ArgumentError{Expected: "[string]"}
	}

	return exec(params.Line, vos)
}
