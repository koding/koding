package lxc

import (
	"errors"

	"github.com/koding/kite"
)

var ErrNotSupported = errors.New("not supported")

func Create(r *kite.Request) (interface{}, error) {
	return apiWrapper(create).ServeKite(r)
}

func Destroy(r *kite.Request) (interface{}, error) {
	return apiWrapper(destroy).ServeKite(r)
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
