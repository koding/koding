package lxc

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/kite-lxc/api"
)

var ErrNotSupported = errors.New("not supported")

var (
	// Create is calling lxc-create with the given CreateParams information
	Create = LXCFunc(create)

	// Destroy is calling lxc-destroy with the given ContainerParams information
	Destroy = LXCFunc(destroy)

	// Start is calling lxc-start with the given ContainerParams information
	Start = LXCFunc(start)

	// Stop is calling lxc-stop with the given ContainerParams information
	Stop = LXCFunc(stop)

	// Info is calling lxc-info with the given ContainerParams information
	Info = LXCFunc(info)
)

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
