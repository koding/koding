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

// lxcFunc implements the kite Handler interface
type lxcFunc func(*kite.Request, *api.LXC) (interface{}, error)

// lxcWrapper creates a new kite.Handler based on the given lxcFunc
func lxcWrapper(fn lxcFunc) kite.Handler {
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

func create(r *kite.Request, l *api.LXC) (interface{}, error) {
	var params CreateParams
	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, fmt.Errorf("invalid arguments: %s", err)
	}

	opts := api.CreateOptions{
		Template: params.Template,
	}

	if err := l.Create(opts); err != nil {
		return nil, err
	}

	return true, nil
}

func start(r *kite.Request, l *api.LXC) (interface{}, error) {
	if err := l.Start(); err != nil {
		return nil, err
	}

	return true, nil
}

func info(r *kite.Request, l *api.LXC) (interface{}, error) {
	return l.Info()
}

func stop(r *kite.Request, l *api.LXC) (interface{}, error) {
	if err := l.Stop(); err != nil {
		return nil, err
	}

	return true, nil
}

func destroy(r *kite.Request, l *api.LXC) (interface{}, error) {
	if err := l.Destroy(); err != nil {
		return nil, err
	}

	return true, nil
}
