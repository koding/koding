package util

import (
	"fmt"

	"github.com/koding/kite"
)

func NewKiteError(t string, err error) *kite.Error {
	return &kite.Error{
		Type:    t,
		Message: err.Error(),
	}
}

// KiteErrorf is akin to fmt.Errorf, taking a type, string format, and data
// to format as a message.
func KiteErrorf(t string, f string, i ...interface{}) *kite.Error {
	return &kite.Error{
		Type:    t,
		Message: fmt.Sprintf(f, i...),
	}
}
