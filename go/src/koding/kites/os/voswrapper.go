// +build linux

package main

import (
	"errors"
	kitelib "kite"
	"koding/virt"
)

type VosFunc func(*kitelib.Request, *virt.VOS) (interface{}, error)

func VosMethod(k *kitelib.Kite, method string, vosFunc VosFunc) {
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

		return vosFunc(r, vos)
	}

	k.HandleFunc(method, handler)
}

func vmStartNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return vmStart(vos)
}
