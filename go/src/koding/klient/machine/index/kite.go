package index

import (
	"github.com/koding/kite"
)

// KiteHandlerHead creates a kite handler function that, when called, invokes
// index package Head method.
func KiteHandlerHead() kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &Request{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := Head(req)
		if err != nil {
			// TODO(ppknap): create errors file similar to kloud/stack/errors.
			return nil, &kite.Error{
				Type:    "indexError",
				Message: err.Error(),
			}
		}

		return res, nil
	}
}

// KiteHandlerGet creates a kite handler function that, when called, invokes
// index package Get method.
func KiteHandlerGet() kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &Request{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := Get(req)
		if err != nil {
			// TODO(ppknap): create errors file similar to kloud/stack/errors.
			return nil, &kite.Error{
				Type:    "indexError",
				Message: err.Error(),
			}
		}

		return res, nil
	}
}
