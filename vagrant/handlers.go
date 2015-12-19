// Package vagrant is a package that provides Kite handlers for dealing with
// Vagrant boxes. Under the hood it uses the github.com/koding/vagrantutil
// package.
package vagrant

import (
	"errors"
	"fmt"
	"sync"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/dnode"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/vagrantutil"
)

// Handlers define a set of kite handlers which is responsible of managing
// vagrant boxes on multiple different paths.
type Handlers struct {
	paths   map[string]*vagrantutil.Vagrant
	pathsMu sync.Mutex // protects paths
}

// NewHandlers returns a new instance of Handlers.
func NewHandlers() *Handlers {
	return &Handlers{
		paths: make(map[string]*vagrantutil.Vagrant),
	}
}

// Info is returned when the Status() or List() methods are called.
type Info struct {
	FilePath string
	State    string
}

type VagrantCreateOptions struct {
	Hostname string
	Box      string
	Memory   int
	Cpus     int
}

type vagrantFunc func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error)

// withPath is a helper function which check if the given vagrantFunc can be
// executed with a valid path.
func (h *Handlers) withPath(r *kite.Request, fn vagrantFunc) (interface{}, error) {
	var params struct {
		FilePath string
	}

	if r.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	err := r.Args.One().Unmarshal(&params)
	if err != nil {
		return nil, err
	}

	if params.FilePath == "" {
		return nil, errors.New("[filePath] is missing")
	}

	// check if it was added previously, if not create a new vagrantUtil
	// instance
	h.pathsMu.Lock()
	v, ok := h.paths[params.FilePath]
	h.pathsMu.Unlock()
	if !ok {
		v, err = vagrantutil.NewVagrant(params.FilePath)
		if err != nil {
			return nil, err
		}

		h.pathsMu.Lock()
		h.paths[params.FilePath] = v
		h.pathsMu.Unlock()
	}

	return fn(r, v)
}

// List returns a list of vagrant boxes with their status, paths and unique ids
func (h *Handlers) List(r *kite.Request) (interface{}, error) {
	fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
		vagrants, err := v.List()
		if err != nil {
			return nil, err
		}

		response := make([]Info, len(vagrants))
		for i, vg := range vagrants {
			response[i] = Info{
				FilePath: vg.VagrantfilePath,
				State:    vg.State,
			}
		}

		return response, nil
	}

	return h.withPath(r, fn)
}

// Create creates the Vagrantfile source inside the specified file path
func (h *Handlers) Create(r *kite.Request) (interface{}, error) {
	fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
		var params struct {
			Vagrantfile string
		}

		if r.Args == nil {
			return nil, errors.New("arguments are not passed")
		}

		if r.Args.One().Unmarshal(&params) != nil || params.Vagrantfile == "" {
			return nil, errors.New("vagrantfile argument is empty")
		}

		// TODO(arslan): this should come through params
		opts := &VagrantCreateOptions{
			Box:      "ubuntu/trusty64",
			Hostname: "arslan",
			Memory:   2048,
			Cpus:     2,
		}

		vagrantFile, err := createTemplate(opts)
		if err != nil {
			return nil, err
		}

		fmt.Println("----------------------------Vagrantfile")
		fmt.Println(vagrantFile)

		if err := v.Create(vagrantFile); err != nil {
			return nil, err
		}

		return true, nil
	}

	return h.withPath(r, fn)
}

// Provider returns the provider of the given Vagrantfile. Such as "virtualbox".
func (h *Handlers) Provider(r *kite.Request) (interface{}, error) {
	fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
		return v.Provider()
	}
	return h.withPath(r, fn)
}

// Destroy destroys the given Vagrant box specified in the path
func (h *Handlers) Destroy(r *kite.Request) (interface{}, error) {
	fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
		return watchCommand(r, v.Destroy)
	}
	return h.withPath(r, fn)
}

// Halt stops the given Vagrant box specified in the path
func (h *Handlers) Halt(r *kite.Request) (interface{}, error) {
	fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
		return watchCommand(r, v.Halt)
	}
	return h.withPath(r, fn)
}

// Up starts and creates the given Vagrant box specified in the path
func (h *Handlers) Up(r *kite.Request) (interface{}, error) {
	fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
		return watchCommand(r, v.Up)
	}
	return h.withPath(r, fn)
}

// Status returns the status of the box specified in the path
func (h *Handlers) Status(r *kite.Request) (interface{}, error) {
	fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
		status, err := v.Status()
		if err != nil {
			return nil, err
		}

		return Info{
			FilePath: v.VagrantfilePath,
			State:    status.String(),
		}, nil
	}
	return h.withPath(r, fn)
}

// Version retursn the Vagrant version of the system
func (h *Handlers) Version(r *kite.Request) (interface{}, error) {
	fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
		return v.Version()
	}
	return h.withPath(r, fn)
}

// watchCommand is an helper method to send back the command outputs of
// commands like Halt,Destroy or Up to the callback function passed in the
// request.
func watchCommand(r *kite.Request, fn func() (<-chan *vagrantutil.CommandOutput, error)) (interface{}, error) {
	var params struct {
		Watch dnode.Function
	}

	if r.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if !params.Watch.IsValid() {
		return nil, errors.New("watch argument is either not passed or it's not a function")
	}

	output, err := fn()
	if err != nil {
		return nil, err
	}

	go func() {
		for out := range output {
			if out.Error != nil {
				params.Watch.Call(fmt.Sprintf("%s failed: %s", r.Method, out.Error.Error()))
				return
			}

			params.Watch.Call(out.Line)
		}
	}()

	return true, nil

}
