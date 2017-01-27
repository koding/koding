package machinegroup

import (
	"github.com/koding/kite"
)

// KiteHandlerCreate creates a kite handler function that, when called, invokes
// machine group Create method.
func KiteHandlerCreate(g *Group) kite.HandlerFunc {
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

// KiteHandlerID creates a kite handler function that, when called, invokes
// machine group ID method.
func KiteHandlerID(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &IDRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.ID(req)
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

// KiteHandlerSSH creates a kite handler function that, when called, invokes
// machine group SSH method.
func KiteHandlerSSH(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &SSHRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.SSH(req)
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

// KiteHandlerHeadMount creates a kite handler function that, when called,
// invokes machine group HeadMount method.
func KiteHandlerHeadMount(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &HeadMountRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		r.LocalKite.Log.Error("---- %s", req)
		res, err := g.HeadMount(req)
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

// KiteHandlerAddMount creates a kite handler function that, when called,
// invokes machine group AddMount method.
func KiteHandlerAddMount(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &AddMountRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.AddMount(req)
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

// KiteHandlerListMount creates a kite handler function that, when called,
// invokes machine group ListMount method.
func KiteHandlerListMount(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &ListMountRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.ListMount(req)
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

// KiteHandlerUmount creates a kite handler function that, when called, invokes
// machine group Umount method.
func KiteHandlerUmount(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &UmountRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.Umount(req)
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
