package lxc

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
)

var ErrNotSupported = errors.New("not supported")

type CreateParams struct {
	Name string
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

	return true, nil
}

func Start(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}

func Stop(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}

func Destroy(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}

func Info(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}

func Ls(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
}
