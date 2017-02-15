// Package vagrant is a package that provides Kite handlers for dealing with
// Vagrant boxes. Under the hood it uses the github.com/koding/vagrantutil
// package.
package vagrant

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	konfig "koding/klient/config"
	"koding/klient/tunnel/tlsproxy/pem"
	"koding/logrotate"

	"github.com/boltdb/bolt"
	"github.com/cenkalti/backoff"
	multierror "github.com/hashicorp/go-multierror"
	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
	"github.com/koding/vagrantutil"
)

var defaultLog = logging.NewCustom("vagrant", false)

// Options are used to alternate default behavior of Handlers.
type Options struct {
	Home   string
	DB     *bolt.DB
	Log    kite.Logger
	Debug  bool
	Output func(string) (io.WriteCloser, error)
}

// Handlers define a set of kite handlers which is responsible of managing
// vagrant boxes on multiple different paths.
type Handlers struct {
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
	opts *Options
}

// NewHandlers returns a new instance of Handlers.
func NewHandlers(opts *Options) *Handlers {
	return &Handlers{
		db:       newStorage(opts),
		paths:    make(map[string]*vagrantutil.Vagrant),
		boxNames: make(map[string]chan<- (chan error)),
		boxPaths: make(map[string]chan<- (chan error)),
		opts:     opts,
	}
}

// Info is returned when the Status() or List() methods are called.
type Info struct {
	FilePath string `json:"filePath"`
	State    string `json:"state"`
	Error    string `json:"error,omitempty"`
}

type ForwardedPort struct {
	GuestPort int `json:"guest,omitempty"`
	HostPort  int `json:"host,omitempty"`
}

type VagrantCreateOptions struct {
	Username         string           `json:"username"`
	Hostname         string           `json:"hostname"`
	Box              string           `json:"box,omitempty"`
	Memory           int              `json:"memory,omitempty"`
	Cpus             int              `json:"cpus,omitempty"`
	ProvisionData    string           `json:"provisionData"`
	CustomScript     string           `json:"customScript,omitempty"`
	FilePath         string           `json:"filePath"`
	ForwardedPorts   []*ForwardedPort `json:"forwarded_ports,omitempty"`
	LogFiles         []string         `json:"logFiles,omitempty"`
	TLSProxyHostname string           `json:"tlsProxyHostname,omitempty"`
	Dirty            bool             `json:"forceDestroy,omitempty"`
}

type ForwardedPortsRequest struct {
	Name string `json:"name"`
}

func (req *ForwardedPortsRequest) Valid() error {
	if req.Name == "" {
		return errors.New("box name is empty")
	}

	return nil
}

var unquoter = strings.NewReplacer("\\n", "\n")

type (
	vagrantFunc func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error)
	commandFunc func() (<-chan *vagrantutil.CommandOutput, error)
)

var nop io.WriteCloser = nopOutput{}

type nopOutput struct{}

func (nopOutput) Write(p []byte) (int, error) { return len(p), nil }
func (nopOutput) Close() error                { return nil }

// withPath is a helper function which check if the given vagrantFunc can be
// executed with a valid path.
func (h *Handlers) withPath(r *kite.Request, fn vagrantFunc) (interface{}, error) {
	// For the first vagrant request initialize the handler lazily and
	// download the default base box. For another request in flight the
	// box will already be downloaded.
	h.once.Do(h.init)

	var params struct {
		FilePath string
		Debug    bool
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

	v, err := h.vagrantutil(params.FilePath, params.Debug)
	if err != nil {
		return nil, err
	}

	h.log().Info("Calling %q on %q", r.Method, v.VagrantfilePath)

	h.log().Debug("vagrant: calling %q by %q with %s", r.Method, r.Username, r.Args.Raw)

	resp, err := fn(r, v)

	h.log().Debug("vagrant: call %q by %q result: resp=%v, err=%v", r.Method, r.Username, resp, err)

	return resp, err
}

// check if it was added previously, if not create a new vagrantUtil
// instance
func (h *Handlers) vagrantutil(path string, debug bool) (*vagrantutil.Vagrant, error) {
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

		if debug || h.opts.Debug {
			v.Log = logging.NewCustom("vagrantutil", true)
		}

		// Set explicitly to virtualbox to overwrite any default
		// provider that may be set system-wide.
		v.ProviderName = "virtualbox"

		h.paths[path] = v
	}

	return v, nil
}

func (h *Handlers) absolute(path string) string {
	if !filepath.IsAbs(path) {
		return filepath.Join(h.opts.Home, path)
	}
	return filepath.Clean(path)
}

func (h *Handlers) list(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
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

// List returns a list of vagrant boxes with their status, paths and unique ids
func (h *Handlers) List(r *kite.Request) (interface{}, error) {
	return h.withPath(r, h.list)
}

func (h *Handlers) create(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
	if r.Args == nil {
		return nil, errors.New("missing arguments")
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

	if params.TLSProxyHostname == "" {
		params.TLSProxyHostname = pem.Hostname
	}

	switch {
	case !params.Dirty:
		// Ensure vagrant working dir has no machine provisioned.
		err := vagrantutil.Wait(v.Destroy())
		if err != nil {
			h.log().Error("unable to destroy before create: %s", err)
			break
		}

		status, err := v.Status()
		if err != nil {
			h.log().Error("unable to check status: %s", err)
			break
		}

		if status != vagrantutil.NotCreated {
			h.log().Error("dirty Vagrant directory: want status to be %v, was %v", vagrantutil.NotCreated, status)
		}
	}

	h.boxAdd(v, params.Box, params.FilePath)

	vagrantFile, err := createTemplate(&params)
	if err != nil {
		return nil, err
	}

	if err := v.Create(vagrantFile); err != nil {
		return nil, err
	}

	return params, nil
}

// Create creates the Vagrantfile source inside the specified file path
func (h *Handlers) Create(r *kite.Request) (interface{}, error) {
	return h.withPath(r, h.create)
}

func (h *Handlers) provider(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
	return v.Provider()
}

// Provider returns the provider of the given Vagrantfile. Such as "virtualbox".
func (h *Handlers) Provider(r *kite.Request) (interface{}, error) {
	return h.withPath(r, h.provider)
}

func (h *Handlers) destroy(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
	return h.watchCommand(r, v.VagrantfilePath, v.Destroy)
}

// Destroy destroys the given Vagrant box specified in the path
func (h *Handlers) Destroy(r *kite.Request) (interface{}, error) {
	return h.withPath(r, h.destroy)
}

func (h *Handlers) halt(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
	return h.watchCommand(r, v.VagrantfilePath, v.Halt)
}

// Halt stops the given Vagrant box specified in the path
func (h *Handlers) Halt(r *kite.Request) (interface{}, error) {
	return h.withPath(r, h.halt)
}

func (h *Handlers) up(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
	if err := h.boxWait(v.VagrantfilePath); err != nil {
		return nil, err
	}

	return h.watchCommand(r, v.VagrantfilePath, v.Up)
}

// Up starts and creates the given Vagrant box specified in the path
func (h *Handlers) Up(r *kite.Request) (interface{}, error) {
	return h.withPath(r, h.up)
}

func (h *Handlers) status(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
	status, err := v.Status()
	if err != nil {
		return nil, err
	}

	return Info{
		FilePath: v.VagrantfilePath,
		State:    status.String(),
	}, nil
}

// Status returns the status of the box specified in the path
func (h *Handlers) Status(r *kite.Request) (interface{}, error) {
	return h.withPath(r, h.status)
}

type versionRequest struct {
	Name string `json:"name"`
}

type versionResponse struct {
	Vagrant string `json:"vagrant,omitempty"`
	Klient  string `json:"klient,omitempty"`
}

func (h *Handlers) version(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
	if r.Args == nil {
		return nil, errors.New("missing arguments")
	}

	var req versionRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	var resp versionResponse

	switch req.Name {
	case "klient":
		resp.Klient = konfig.Version
	case "vagrant":
		ver, err := v.Version()
		if err != nil {
			return nil, err
		}

		resp.Vagrant = ver
	case "":
		// Backward-compatibility with old kloud version.
		//
		// TODO(rjeczalik): If you read this probably it can be removed.
		return v.Version()
	}

	return &resp, nil
}

// Version returns the Vagrant version of the system
func (h *Handlers) Version(r *kite.Request) (interface{}, error) {
	return h.withPath(r, h.version)
}

// ForwardedPorts lists all forwarded port rules for the given box.
func (h *Handlers) ForwardedPorts(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, errors.New("no arguments")
	}

	var req ForwardedPortsRequest
	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	if err := req.Valid(); err != nil {
		return nil, err
	}

	name, err := h.vboxLookupName(req.Name)
	if err != nil {
		return nil, fmt.Errorf("unable to find box %q: %s", req.Name, err)
	}

	ports, err := h.vboxForwardedPorts(name)
	if err != nil {
		return nil, fmt.Errorf("unable to read forwarded ports for box %q: %s", name, err)
	}

	return ports, nil
}

func (h *Handlers) boxAdd(v *vagrantutil.Vagrant, box, filePath string) {
	h.boxMu.Lock()
	defer h.boxMu.Unlock()

	queue, ok := h.boxNames[box]
	if !ok {
		ch := make(chan chan error, 1)
		h.boxNames[box] = ch
		go h.download(v, box, filePath, ch)
		queue = ch
	}

	h.boxPaths[filePath] = queue
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

func (h *Handlers) download(v *vagrantutil.Vagrant, box, filePath string, queue <-chan chan error) {
	h.log().Debug("downloading %q box...", box)

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
			delete(h.boxPaths, filePath)
			h.boxMu.Unlock()

			// Defensive channel drain: try to collect listeners
			// that may have registered after receiving from done
			// but before taking boxMu lock.
			listeners = append(listeners, drain(queue)...)

			// Notify all listeners.
			for _, l := range listeners {
				l <- err
			}

			h.log().Debug("downloading %q box finished: err=%v", box, err)

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
		h.log().Error("failed to init Vagrant handlers: %s", err)
		return
	}

	h.boxAdd(v, "ubuntu/trusty64", "")

	if err := os.MkdirAll(filepath.Join(h.opts.Home, "logs"), 0755); err != nil {
		h.log().Error("failed to init Vagrant handlers: %s", err)
	}
}

func (h *Handlers) log() kite.Logger {
	if h.opts.Log != nil {
		return h.opts.Log
	}

	return defaultLog
}

func (h *Handlers) output(path string) (io.WriteCloser, error) {
	if h.opts.Output != nil {
		return h.opts.Output(path)
	}

	return nop, nil
}

// watchCommand is an helper method to send back the command outputs of
// commands like Halt,Destroy or Up to the callback function passed in the
// request.
func (h *Handlers) watchCommand(r *kite.Request, filePath string, fn commandFunc) (interface{}, error) {
	var params struct {
		Success   dnode.Function
		Failure   dnode.Function
		Output    dnode.Function
		Heartbeat dnode.Function
	}

	if r.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	path := filepath.Join(h.opts.Home, "logs", filepath.Base(filePath), strings.ToLower(r.Method)+"-"+r.ID+".log")

	output, err := h.output(path)
	if err != nil {
		return nil, err
	}

	fail := func(err error) error {
		go retry(func() error {
			return params.Failure.Call(err.Error())
		})

		if e := output.Close(); e != nil {
			h.log().Warning("failure closing %q: %s", path, e)
		}

		return err
	}

	if !params.Failure.IsValid() {
		return nil, errors.New("invalid request: missing failure callback")
	}

	if !params.Success.IsValid() {
		return nil, fail(errors.New("invalid request: missing success callback"))
	}

	var verr error
	var fns OutputFuncs

	fns = append(fns, func(line string) {
		fmt.Fprintln(output, line)

		i := strings.Index(strings.ToLower(line), "error:")
		if i == -1 {
			return
		}

		msg := strings.TrimSpace(line[i+len("error:"):])

		if msg != "" {
			msg = unquoter.Replace(msg)
			verr = multierror.Append(verr, errors.New(msg))
		}
	})

	if params.Output.IsValid() {
		h.log().Debug("sending output to %q for %q", r.Username, r.Method)

		fns = append(fns, func(line string) {
			h.log().Debug("%s: %s", r.Method, line)
			params.Output.Call(line)
		})
	}

	w := &vagrantutil.Waiter{
		OutputFunc: fns.Output,
	}

	out, err := fn()
	if err != nil {
		return nil, fail(err)
	}

	go func() {
		h.log().Debug("vagrant: waiting for output from %q...", r.Method)

		defer func() {
			if err := output.Close(); err != nil && !logrotate.IsNop(err) {
				h.log().Warning("failure closing %q: %s", path, err)
			}
		}()

		if params.Heartbeat.IsValid() {
			stop := make(chan struct{})
			defer close(stop)

			go func() {
				t := time.NewTicker(5 * time.Second)
				defer t.Stop()

				for {
					select {
					case <-stop:
						h.log().Debug("stopping heartbeat for %q", filePath)
						return
					case <-t.C:
						h.log().Debug("sending heartbeat for %q", filePath)

						if err := params.Heartbeat.Call(); err != nil {
							h.log().Debug("heartbeat failure for %q: %s", filePath, err)
						}
					}
				}
			}()
		}

		err := w.Wait(out, nil)

		if err != nil {
			verr = multierror.Append(verr, err)

			h.log().Error("Klient %q error for %q: %s", r.Method, filePath, verr)
			fail(verr)
			return
		}

		h.log().Info("Klient %q success for %q", r.Method, filePath)

		retry(func() error {
			return params.Success.Call()
		})
	}()

	return true, nil
}

func retry(op func() error) {
	retry := backoff.NewExponentialBackOff()
	retry.MaxElapsedTime = 2 * time.Minute
	retry.MaxInterval = 10 * time.Second

	backoff.Retry(op, retry)
}
