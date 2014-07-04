package lxc

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/kite-lxc/api"
)

var ErrNotSupported = errors.New("not supported")

type CreateParams struct {
	Name     string
	Template string
}

func Create(r *kite.Request) (interface{}, error) {
	var params CreateParams
	if r.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, fmt.Errorf("invalid arguments: %s", err)
	}

	if params.Name == "" {
		return nil, errors.New("container name is not given")
	}

	l := api.New(params.Name)

	opts := api.CreateOptions{
		Template: params.Template,
	}

	if err := l.Create(opts); err != nil {
		return nil, err
	}

	return true, nil
}

func Destroy(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}

func Start(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}

func Stop(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}

func Info(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}

func Ls(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}
