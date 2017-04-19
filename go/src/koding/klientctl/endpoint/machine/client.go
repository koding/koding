package machine

import (
	"sync"

	"koding/kites/config"
	"koding/kites/kloud/stack"
	"koding/klient/machine"
	"koding/klient/machine/machinegroup"
	"koding/klient/os"
	konfig "koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
	koding "koding/klientctl/endpoint/remoteapi"
	"koding/remoteapi/models"

	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
)

// DefaultClient is a default client used by all machine functions.
var DefaultClient = &Client{}

func init() {
	ctlcli.CloseOnExit(DefaultClient)
}

// Client is responsible for machine operations like:
//
//   - starting, stopping and listing machines
//   - creating, deleting and listing mounts
//
type Client struct {
	Konfig *config.Konfig
	Klient kloud.Transport
	Kloud  *kloud.Client
	Koding *koding.Client
	Log    logging.Logger

	k        kloud.Transport
	once     sync.Once // for c.init()
	machines map[string]*models.JMachine
}

// ExecOptions represents available parameters for the Exec method.
type ExecOptions struct {
	MachineID string       // machine ID
	Path      string       // if it resides inside existing mount, machine ID is inferred from it
	Cmd       string       // binary to execute
	Args      []string     // command line flags for the binary
	Stdout    func(string) // stdout callback, called in-order if not nil
	Stderr    func(string) // stderr callback, called in-order if not nil
	Exit      func(int)    // process exit callback, guaranteed to get called last if not nil
}

// KillOptions represents available parameters for the Kill method.
type KillOptions struct {
	MachineID string // machine ID
	Path      string // if it resides inside existing mount, machine ID is inferred from it
	PID       int    // pid of the remote process
}

// Exec runs the given command in a remote machine.
func (c *Client) Exec(opts *ExecOptions) (int, error) {
	req := &machinegroup.ExecRequest{
		ExecRequest: os.ExecRequest{
			Cmd:  opts.Cmd,
			Args: opts.Args,
		},
		MachineRequest: machinegroup.MachineRequest{
			MachineID: machine.ID(opts.MachineID),
			Path:      opts.Path,
		},
	}

	if opts.Stdout != nil {
		req.Stdout = dnode.Callback(func(r *dnode.Partial) {
			opts.Stdout(r.One().MustString())
		})
	}

	if opts.Stderr != nil {
		req.Stderr = dnode.Callback(func(r *dnode.Partial) {
			opts.Stderr(r.One().MustString())
		})
	}

	if opts.Exit != nil {
		req.Exit = dnode.Callback(func(r *dnode.Partial) {
			var exit int
			r.One().MustUnmarshal(&exit)
			opts.Exit(exit)
		})
	}

	var resp machinegroup.ExecResponse

	if err := c.klient().Call("machine.exec", req, &resp); err != nil {
		return 0, err
	}

	return resp.PID, nil
}

// Kill terminates a running process on a remote machine.
func (c *Client) Kill(opts *KillOptions) error {
	req := &machinegroup.KillRequest{
		KillRequest: os.KillRequest{
			PID: opts.PID,
		},
		MachineRequest: machinegroup.MachineRequest{
			MachineID: machine.ID(opts.MachineID),
			Path:      opts.Path,
		},
	}

	return c.klient().Call("machine.kill", req, nil)
}

func (c *Client) Start(id string) (string, error) {
	c.init()

	return c.machineCall(id, "start")
}

func (c *Client) Stop(id string) (string, error) {
	c.init()

	return c.machineCall(id, "stop")
}

func (c *Client) machineCall(id, method string) (string, error) {
	m, err := c.machine(id)
	if err != nil {
		return "", err
	}

	req := &machineReq{
		MachineId: id,
		Provider:  *m.Provider,
	}
	var resp machineResp

	if err := c.kloud().Call(method, req, &resp); err != nil {
		return "", err
	}

	return resp.EventId, nil
}

type machineReq struct {
	MachineId string
	Provider  string
}

type machineResp struct {
	EventId string
}

func (c *Client) machine(id string) (*models.JMachine, error) {
	if m, ok := c.machines[id]; ok {
		return m, nil
	}

	f := &koding.Filter{
		ID: id,
	}

	m, err := c.koding().ListMachines(f)
	if err != nil {
		return nil, err
	}

	for _, m := range m {
		c.machines[m.ID] = m
	}

	if m, ok := c.machines[id]; ok {
		return m, nil
	}

	return nil, koding.ErrNotFound
}

func (c *Client) Close() (err error) {
	if len(c.machines) != 0 {
		err = c.kloud().Cache().SetValue("machine", c.machines)
	}
	return err
}

func (c *Client) init() {
	c.once.Do(c.readCache)
}

func (c *Client) readCache() {
	c.machines = make(map[string]*models.JMachine)

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.kloud().Cache().GetValue("machine", &c.machines)
}

func (c *Client) konfig() *config.Konfig {
	if c.Konfig != nil {
		return c.Konfig
	}
	return konfig.Konfig
}

func (c *Client) klient() kloud.Transport {
	if c.Klient != nil {
		return c.Klient
	}

	if c.k == nil {
		c.k = &kloud.KiteTransport{
			ClientURL: c.konfig().Endpoints.Klient.Private.String(),
		}
	}

	return c.k
}

func (c *Client) koding() *koding.Client {
	if c.Koding != nil {
		return c.Koding
	}
	return koding.DefaultClient
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func (c *Client) log() logging.Logger {
	if c.Log != nil {
		return c.Log
	}
	return kloud.DefaultLog
}

// Exec runs the given command in a remote machine using DefaultClient.
func Exec(opts *ExecOptions) (int, error) { return DefaultClient.Exec(opts) }

// Kill terminates a command looked up by the given pid on a remote machine
// using DefaultClient.
func Kill(opts *KillOptions) error { return DefaultClient.Kill(opts) }

// Start starts a remove vm given by the id.
func Start(id string) (string, error) { return DefaultClient.Start(id) }

// Stop stops a remove vm given by the id.
func Stop(id string) (string, error) { return DefaultClient.Stop(id) }

// Wait polls on event stream given by the event identifier.
//
// It closes the returned channel as soon as stream state reaches
// 100% or an error occurs.
func Wait(event string) <-chan *stack.EventResponse {
	return DefaultClient.kloud().Wait(event)
}
