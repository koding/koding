package lxc

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/kite-lxc/api"
)

type CreateParams struct {
	Name     string
	Template string
}

type ContainerParams struct {
	Name       string
	ConfigPath string
}

// LxcFunc implements the kite Handler interface
type LXCFunc func(*kite.Request, *api.LXC) (interface{}, error)

func (l LXCFunc) ServeKite(r *kite.Request) (interface{}, error) {
	return lxcWrapper(l).ServeKite(r)
}

// lxcWrapper creates a new kite.Handler based on the given LXCFunc
func lxcWrapper(fn LXCFunc) kite.Handler {
	return kite.HandlerFunc(func(r *kite.Request) (response interface{}, err error) {
		if r.Args == nil {
			return nil, errors.New("arguments are not passed")
		}

		// We only accept a struct and in every incoming struct we expect the
		// Name field. This is a must and an enforcement by us. ConfigPath
		// is optional.
		var params ContainerParams

		if err := r.Args.One().Unmarshal(&params); err != nil {
			return nil, fmt.Errorf("invalid arguments: %s", err)
		}

		if params.Name == "" {
			return nil, errors.New("container name is not given")
		}

		l := api.New(params.Name)
		if params.ConfigPath != "" {
			l = api.NewWithPath(params.Name, params.ConfigPath)
		}

		// call our kite handler with the the lxc api context
		return fn(r, l)
	})

}
