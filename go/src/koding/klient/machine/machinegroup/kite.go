package machinegroup

import (
	"github.com/koding/kite"
)

// TODO(ppknap): create errors file similar to kloud/stack/errors.
func newError(err error) error {
	if e, ok := err.(*kite.Error); ok {
		return e
	}

	return &kite.Error{
		Type:    "machinesError",
		Message: err.Error(),
	}
}

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
			return nil, newError(err)
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
			return nil, newError(err)
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
			return nil, newError(err)
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

		res, err := g.HeadMount(req)
		if err != nil {
			return nil, newError(err)
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
			return nil, newError(err)
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
			return nil, newError(err)
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
			return nil, newError(err)
		}

		return res, nil
	}
}

// HandleExec is a handler for "machine.exec" kite requests.
func (g *Group) HandleExec(r *kite.Request) (interface{}, error) {
	var req ExecRequest

	if r.Args != nil {
		if err := r.Args.One().Unmarshal(&req); err != nil {
			return nil, err
		}
	}

	if err := req.Valid(); err != nil {
		return nil, newError(err)
	}

	resp, err := g.Exec(&req)
	if err != nil {
		return nil, newError(err)
	}

	return resp, nil
}

// HandleKill is a handler for "machine.kill" kite requests.
func (g *Group) HandleKill(r *kite.Request) (interface{}, error) {
	var req KillRequest

	if r.Args != nil {
		if err := r.Args.One().Unmarshal(&req); err != nil {
			return nil, err
		}
	}

	resp, err := g.Kill(&req)
	if err != nil {
		return nil, newError(err)
	}

	return resp, nil
}
