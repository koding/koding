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

// KiteHandlerIdentifierList creates a kite handler function that, when called,
// invokes machine group IdentifierList method.
func KiteHandlerIdentifierList(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &IdentifierListRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.IdentifierList(req)
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

// KiteHandlerUpdateIndex creates a kite handler function that, when called,
// invokes machine group UpdateIndex method.
func KiteHandlerUpdateIndex(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &UpdateIndexRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.UpdateIndex(req)
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

// KiteHandlerInspectMount creates a kite handler function that, when called,
// invokes machine group InspectMount method.
func KiteHandlerInspectMount(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &InspectMountRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.InspectMount(req)
		if err != nil {
			return nil, newError(err)
		}

		return res, nil
	}
}

// KiteHandlerCp creates a kite handler function that, when called, invokes
// machine group Cp method.
func KiteHandlerCp(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &CpRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.Cp(req)
		if err != nil {
			return nil, newError(err)
		}

		return res, nil
	}
}

// KiteHandlerMountID creates a kite handler function that, when called, invokes
// machine group MountID method.
func KiteHandlerMountID(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &MountIDRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.MountID(req)
		if err != nil {
			return nil, newError(err)
		}

		return res, nil
	}
}

// KiteHandlerMountIdentifierList creates a kite handler function that, when
// called, invokes machine group MountIdentifierList method.
func KiteHandlerMountIdentifierList(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &MountIdentifierListRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.MountIdentifierList(req)
		if err != nil {
			return nil, newError(err)
		}

		return res, nil
	}
}

// KiteHandlerManageMount creates a kite handler function that, when called,
// invokes machine group ManageMount method.
func KiteHandlerManageMount(g *Group) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		req := &ManageMountRequest{}

		if r.Args != nil {
			if err := r.Args.One().Unmarshal(req); err != nil {
				return nil, err
			}
		}

		res, err := g.ManageMount(req)
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

	if err := req.Valid(); err != nil {
		return nil, newError(err)
	}

	resp, err := g.Kill(&req)
	if err != nil {
		return nil, newError(err)
	}

	return resp, nil
}

// HandleWaitIdle is a handler for "machine.mount.waitIdle" kite requests.
func (g *Group) HandleWaitIdle(r *kite.Request) (interface{}, error) {
	var req WaitIdleRequest

	if r.Args != nil {
		if err := r.Args.One().Unmarshal(&req); err != nil {
			return nil, err
		}
	}

	if err := req.Valid(); err != nil {
		return nil, newError(err)
	}

	if err := g.WaitIdle(&req); err != nil {
		return nil, newError(err)
	}

	return nil, nil
}
