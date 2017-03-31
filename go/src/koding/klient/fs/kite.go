package fs

import (
	"github.com/koding/kite"
)

// KiteHandlerAbs creates a kite handler function that, when called, invokes
// default file system Abs method.
func KiteHandlerAbs() kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &AbsRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := Abs(req)
		if err != nil {
			// TODO(ppknap): create errors file similar to kloud/stack/errors.
			return nil, &kite.Error{
				Type:    "fsError",
				Message: err.Error(),
			}
		}

		return res, nil
	}
}
