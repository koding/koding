package lxc

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/kite-lxc/api"
)

var ErrNotSupported = errors.New("not supported")

var (
	Create  = lxcFunc(create)
	Destroy = lxcFunc(destroy)
	Start   = lxcFunc(start)
	Stop    = lxcFunc(stop)
	Info    = lxcFunc(info)
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
