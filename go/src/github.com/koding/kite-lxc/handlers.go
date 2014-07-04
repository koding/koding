package lxc

import (
	"errors"

	"github.com/koding/kite"
)

var ErrNotSupported = errors.New("not supported")

func Create(r *kite.Request) (interface{}, error) {
	return nil, ErrNotSupported
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
