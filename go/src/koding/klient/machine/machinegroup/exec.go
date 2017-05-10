package machinegroup

import (
	"errors"
	stdos "os"
	"path/filepath"
	"strings"

	"koding/klient/machine"
	"koding/klient/machine/mount"
	"koding/klient/os"

	"github.com/koding/kite/dnode"
)

// MachineRequest represents a common part of Exec and Kill
// requests, which is used for looking up a remote machine.
type MachineRequest struct {
	MachineID machine.ID `json:"machineID"`
	Path      string     `json:"path"`
}

// Valid implements the stack.Validator interface.
func (r *MachineRequest) Valid() error {
	if r.MachineID == "" && r.Path == "" {
		return errors.New("both path and machine ID are empty")
	}
	if r.Path != "" && !filepath.IsAbs(r.Path) {
		return errors.New("invalid relative path")
	}
	return nil
}

// ExecRequest is a request value of "machine.exec" kite method.
type ExecRequest struct {
	os.ExecRequest // request value for remote "os.exec" call
	MachineRequest // used to look up remote
}

// Valid implements the stack.Validator interface.
func (r *ExecRequest) Valid() error {
	if err := r.ExecRequest.Valid(); err != nil {
		return err
	}
	if err := r.MachineRequest.Valid(); err != nil {
		return err
	}

	// dnode.Function cannot be forwarded, they need to be
	// wrapped again in a callback.

	if fn := r.ExecRequest.Stdout; fn.IsValid() {
		r.ExecRequest.Stdout = dnode.Callback(func(r *dnode.Partial) {
			fn.Call(r.One().MustString())
		})
	}
	if fn := r.ExecRequest.Stderr; fn.IsValid() {
		r.ExecRequest.Stderr = dnode.Callback(func(r *dnode.Partial) {
			fn.Call(r.One().MustString())
		})
	}
	if fn := r.ExecRequest.Exit; fn.IsValid() {
		r.ExecRequest.Exit = dnode.Callback(func(r *dnode.Partial) {
			var exit int
			r.One().MustUnmarshal(&exit)
			fn.Call(exit)
		})
	}
	return nil
}

// ExecResponse is a response value of "machine.exec" kite method.
type ExecResponse struct {
	os.ExecResponse // response value from remote "os.exec" call
}

// KillRequest is a request value of "machine.kill" kite method.
type KillRequest struct {
	os.KillRequest // request vaue for remote "os.kill" call
	MachineRequest // used to look up remote
}

// Valid implements the stack.Validator interface.
func (r *KillRequest) Valid() error {
	if err := r.KillRequest.Valid(); err != nil {
		return err
	}
	return r.MachineRequest.Valid()
}

// KillReponse is a response value of "machine.kill" kite method.
type KillResponse struct {
	os.KillResponse
}

// Exec is a handler implementation for "machine.exec" kite method.
func (g *Group) Exec(r *ExecRequest) (*ExecResponse, error) {
	machineID := r.MachineID

	if machineID == "" {
		id, path, err := g.lookup(r.Path)
		if err != nil {
			return nil, err
		}

		machineID, err = g.mount.MachineID(id)
		if err != nil {
			return nil, err
		}

		if r.WorkDir == "" {
			mounts, err := g.mount.All(machineID)
			if err != nil {
				return nil, err
			}

			m, ok := mounts[id]
			if !ok {
				return nil, mount.ErrMountNotFound
			}

			rel, err := filepath.Rel(path, r.Path)
			if err != nil {
				return nil, err
			}

			r.WorkDir = filepath.Join(m.RemotePath, rel)
		}
	}

	c, err := g.client.Client(machineID)
	if err != nil {
		return nil, err
	}

	resp, err := c.Exec(&r.ExecRequest)
	if err != nil {
		return nil, err
	}

	return &ExecResponse{
		ExecResponse: *resp,
	}, nil
}

// Kill is a handler implementation for "method.kill" kite method.
func (g *Group) Kill(r *KillRequest) (*KillResponse, error) {
	machineID := r.MachineID

	if machineID == "" {
		id, _, err := g.lookup(r.Path)
		if err != nil {
			return nil, err
		}

		machineID, err = g.mount.MachineID(id)
		if err != nil {
			return nil, err
		}
	}

	c, err := g.client.Client(machineID)
	if err != nil {
		return nil, err
	}

	resp, err := c.Kill(&r.KillRequest)
	if err != nil {
		return nil, err
	}

	return &KillResponse{
		KillResponse: *resp,
	}, nil

	return nil, nil
}

func (g *Group) lookup(path string) (mount.ID, string, error) {
	const sep = string(stdos.PathListSeparator)

	for path != "" && path != "/" {
		id, err := g.mount.Path(path)
		if err == nil {
			return id, path, nil
		}
		if err != mount.ErrMountNotFound {
			return "", "", err
		}

		if i := strings.LastIndex(path, sep); i != -1 {
			path = path[:i]
			continue
		}

		break
	}

	return "", "", mount.ErrMountNotFound
}
