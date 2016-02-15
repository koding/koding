// Package vagrant is a package that provides Kite handlers for dealing with
// Vagrant boxes. Under the hood it uses the github.com/koding/vagrantutil
// package.
package vagrant

import (
	"errors"
	"fmt"
	"path/filepath"
	"sync"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/vagrantutil"
)

const magicEnd = "guCnvNVedAQT8DiNpcP3pVqzseJvLY"

// Options are used to alternate default behavior of Handlers.
type Options struct {
	Home string
	DB   *bolt.DB
	Log  kite.Logger
}

// Handlers define a set of kite handlers which is responsible of managing
// vagrant boxes on multiple different paths.
type Handlers struct {
	home    string
	log     kite.Logger
	paths   map[string]*vagrantutil.Vagrant
	pathsMu sync.Mutex // protects paths

	// db stores machine status.
	db Storage

	// The following fields implement the singleflight pattern, for
	// each concurrent request there'll be only one ongoing operation
	// upon which completion all the request handlers will get notified
	// about the result.
	boxNames map[string]chan<- (chan error) // queue of listeners mapped by a base box name
	boxPaths map[string]chan<- (chan error) // queue of listeners mapped by a box filePath
	boxMu    sync.Mutex                     // protects boxNames and boxPaths

	once sync.Once
}

// NewHandlers returns a new instance of Handlers.
func NewHandlers(opts *Options) *Handlers {
	return &Handlers{
		home:     opts.Home,
		log:      opts.Log,
		db:       newStorage(opts),
		paths:    make(map[string]*vagrantutil.Vagrant),
		boxNames: make(map[string]chan<- (chan error)),
		boxPaths: make(map[string]chan<- (chan error)),
	}
}

// Info is returned when the Status() or List() methods are called.
type Info struct {
	FilePath string `json:"filePath"`
	State    string `json:"state"`
	Error    string `json:"error,omitempty"`
}

type VagrantCreateOptions struct {
	Hostname      string
	Box           string
	Memory        int
	Cpus          int
	ProvisionData string
	CustomScript  string
	FilePath      string
}

type vagrantFunc func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error)

// withPath is a helper function which check if the given vagrantFunc can be
// executed with a valid path.
func (h *Handlers) withPath(r *kite.Request, fn vagrantFunc) (interface{}, error) {
	// For the first vagrant request initialize the handler lazily and
	// download the default base box. For another request in flight the
	// box will already be downloaded.
	h.once.Do(h.init)

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

	v, err := h.vagrantutil(params.FilePath)
	if err != nil {
		return nil, err
	}

	if err := h.boxWait(v.VagrantfilePath); err != nil {
		return nil, err
	}

	return fn(r, v)
}

// check if it was added previously, if not create a new vagrantUtil
// instance
func (h *Handlers) vagrantutil(path string) (*vagrantutil.Vagrant, error) {
	path = h.absolute(path)

	h.pathsMu.Lock()
	defer h.pathsMu.Unlock()

	v, ok := h.paths[path]
	if !ok {
		var err error
		v, err = vagrantutil.NewVagrant(path)
		if err != nil {
			return nil, err
		}

		h.paths[path] = v
	}

	return v, nil
}

func (h *Handlers) absolute(path string) string {
	if !filepath.IsAbs(path) {
		return filepath.Join(h.home, path)
	}
	return filepath.Clean(path)
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
		if r.Args == nil {
			return nil, errors.New("arguments are not passed")
		}

		var params VagrantCreateOptions
		if err := r.Args.One().Unmarshal(&params); err != nil {
			return nil, err
		}

		params.FilePath = h.absolute(params.FilePath)

		if params.Box == "" {
			params.Box = "ubuntu/trusty64"
		}

		if params.Hostname == "" {
			params.Hostname = r.LocalKite.Config.Username
		}

		if params.Memory == 0 {
			params.Memory = 1024
		}

		if params.Cpus == 0 {
			params.Cpus = 1
		}

		vagrantFile, err := createTemplate(&params)
		if err != nil {
			return nil, err
		}

		if err := v.Create(vagrantFile); err != nil {
			return nil, err
		}

		h.boxAdd(v, params.Box, params.FilePath)

		return params, nil
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

func (h *Handlers) boxAdd(v *vagrantutil.Vagrant, box, filePath string) {
	h.boxMu.Lock()
	defer h.boxMu.Unlock()

	queue, ok := h.boxNames[box]
	if !ok {
		ch := make(chan chan error, 1)
		h.boxNames[box] = ch
		go h.download(v, box, ch)
		queue = ch
	}

	if filePath != "" {
		h.boxPaths[filePath] = queue
	}
}

func drain(queue <-chan chan error) (listeners []chan error) {
	for {
		select {
		case l := <-queue:
			listeners = append(listeners, l)
		default:
			return listeners
		}
	}
}

func (h *Handlers) download(v *vagrantutil.Vagrant, box string, queue <-chan chan error) {
	h.log.Debug("downloading %q box...", box)

	var listeners []chan error
	done := make(chan error)

	go func() {
		err := vagrantutil.Wait(v.BoxAdd(&vagrantutil.Box{Name: box}))
		if err == vagrantutil.ErrBoxAlreadyExists {
			// Ignore the above error.
			err = nil
		}

		done <- err
	}()

	for {
		select {
		case l := <-queue:
			listeners = append(listeners, l)
		case err := <-done:
			// Remove the box from in progress.
			h.boxMu.Lock()
			delete(h.boxNames, box)
			delete(h.boxPaths, box)
			h.boxMu.Unlock()

			// Defensive channel drain: try to collect listeners
			// that may have registered after receiving from done
			// but before taking boxMu lock.
			listeners = append(listeners, drain(queue)...)

			// Notify all listeners.
			for _, l := range listeners {
				l <- err
			}

			h.log.Debug("downloading %q box finished: err=%v", box, err)

			return
		}
	}
}

func (h *Handlers) boxWait(filePath string) error {
	h.boxMu.Lock()
	queue, ok := h.boxPaths[filePath]
	h.boxMu.Unlock()
	if !ok {
		return nil
	}

	wait := make(chan error, 1)
	queue <- wait
	return <-wait
}

func (h *Handlers) init() {
	v, err := vagrantutil.NewVagrant(".") // "vagrant box" commands does not require working dir
	if err != nil {
		h.log.Error("failed to init Vagrant handlers: %s", err)
		return
	}
	h.boxAdd(v, "ubuntu/trusty64", "")
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
				params.Watch.Call(magicEnd)
				return
			}

			params.Watch.Call(out.Line)
		}

		params.Watch.Call(magicEnd)
	}()

	return true, nil
}
