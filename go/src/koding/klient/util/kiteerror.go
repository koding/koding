package util

import "github.com/koding/kite"

func NewKiteError(t string, err error) *kite.Error {
	return &kite.Error{
		Type:    t,
		Message: err.Error(),
	}
}
