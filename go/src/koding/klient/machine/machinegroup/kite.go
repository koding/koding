package machinegroup

import (
	"github.com/koding/kite"
)

// KiteCreateHandler creates a kite handler function that, when called, invokes
// machine group create method.
func KiteCreateHandler(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &CreateRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.Create(req)
		if err != nil {
			// TODO(ppknap): create errors file similar to kloud/stack/errors.
			return nil, &kite.Error{
				Type:    "machinesError",
				Message: err.Error(),
			}
		}

		return res, nil
	}
}
