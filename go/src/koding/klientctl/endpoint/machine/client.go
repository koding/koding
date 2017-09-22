package machine

import (
	"errors"
	"fmt"
	"strconv"
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
	"koding/klientctl/stream"
	"koding/remoteapi/models"

	"github.com/koding/kite/dnode"
)

// TODO(rjeczalik): rename to klient package

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
	Stream stream.Streamer

	k        kloud.Transport
	once     sync.Once // for c.init()
	machines map[machine.ID]*models.JMachine
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

// StartOptions represents available parameters for the Start method.
type StartOptions struct {
	Identifier string // Machine identifier.

	AskList func(is, ds []string) (string, error) // Ask for multiple choices.
}

// Start turns a vm on given by the identifier.
func (c *Client) Start(options *StartOptions) (string, error) {
	c.init()

	// Translate identifier to machine ID.
	id, err := c.getMachineID(options.Identifier, options.AskList)
	if err != nil {
		return "", err
	}

	return c.machineCall(id, "start")
}

// StopOptions represents available parameters for the Stop method.
type StopOptions struct {
	Identifier string // Machine identifier.

	AskList func(is, ds []string) (string, error) // Ask for multiple choices.
}

// Stop turns a vm off given by the identifier.
func (c *Client) Stop(options *StopOptions) (string, error) {
	c.init()

	// Translate identifier to machine ID.
	id, err := c.getMachineID(options.Identifier, options.AskList)
	if err != nil {
		return "", err
	}

	return c.machineCall(id, "stop")
}

// ShowOptions represents available parameters for the Show method.
type ShowOptions struct {
	Identifier string // Machine identifier.

	AskList func(is, ds []string) (string, error) // Ask for multiple choices.
}

// Show gets JMachine.meta value of a vm given by the identifier.
func (c *Client) Show(options *ShowOptions) (map[string]interface{}, error) {
	c.init()

	// Translate identifier to machine ID.
	id, err := c.getMachineID(options.Identifier, options.AskList)
	if err != nil {
		return nil, err
	}

	m, err := c.machine(id)
	if err != nil {
		return nil, err
	}

	if meta, ok := m.Meta.(map[string]interface{}); ok && len(meta) > 0 {
		return meta, nil
	}

	return nil, errors.New("no configuration found")
}

// SetOptions represents available parameters for the Set method.
type SetOptions struct {
	Identifier string // Machine identifier.
	Key        string // Key which value will be set.
	Value      string // New key value.

	AskList func(is, ds []string) (string, error) // Ask for multiple choices.
}

// Set sets JMachine.meta.key=value for a vm given by the identifier.
func (c *Client) Set(options *SetOptions) error {
	c.init()

	// Translate identifier to machine ID.
	id, err := c.getMachineID(options.Identifier, options.AskList)
	if err != nil {
		return err
	}

	switch options.Key {
	case "alwaysOn":
		return c.setAlwaysOn(id, options.Value)
	default:
		return fmt.Errorf(`unsupported %q key; supported ones: "alwaysOn"`, options.Value)
	}
}

func (c *Client) setAlwaysOn(id machine.ID, key string) error {
	on, err := strconv.ParseBool(key)
	if err != nil {
		return err
	}

	m, err := c.machine(id)
	if err != nil {
		return err
	}

	return c.koding().UpdateMachineAlwaysOn(m, on)
}

func (c *Client) machineCall(id machine.ID, method string) (string, error) {
	m, err := c.machine(id)
	if err != nil {
		return "", err
	}

	req := &machineReq{
		MachineId: m.ID,
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

func (c *Client) machine(id machine.ID) (*models.JMachine, error) {
	if jm, ok := c.machines[id]; ok {
		return jm, nil
	}

	f := &koding.Filter{
		ID: string(id),
	}

	m, err := c.koding().ListMachines(f)
	if err != nil {
		return nil, err
	}

	if len(m) != 1 {
		return nil, fmt.Errorf("invalid number of machines received; got %d", len(m))
	}

	c.machines[machine.ID(m[0].ID)] = m[0]

	return m[0], nil
}

func (c *Client) Close() (err error) {
	if len(c.machines) != 0 {
		err = c.kloud().Cache().ReadWrite().SetValue("machine", c.machines)
	}
	return err
}

func (c *Client) init() {
	c.once.Do(c.readCache)
}

func (c *Client) readCache() {
	c.machines = make(map[machine.ID]*models.JMachine)

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.kloud().Cache().ReadOnly().GetValue("machine", &c.machines)
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

func (c *Client) stream() stream.Streamer {
	if c.Stream != nil {
		return c.Stream
	}
	return stream.DefaultStreams
}

func (c *Client) getMachineID(str string, askList func(is, ds []string) (string, error)) (machine.ID, error) {
	idReq := &machinegroup.IDRequest{
		Identifier: str,
	}
	var idRes machinegroup.IDResponse

	if err := c.klient().Call("machine.id", idReq, &idRes); err != nil {
		return "", err
	}

	strID, err := askList(idRes.IDSlice().StringSlice(), idRes.ItemDesc())
	if err != nil {
		return "", err
	}

	return machine.ID(strID), nil
}

// Exec runs the given command in a remote machine using DefaultClient.
func Exec(opts *ExecOptions) (int, error) { return DefaultClient.Exec(opts) }

// Kill terminates a command looked up by the given pid on a remote machine
// using DefaultClient.
func Kill(opts *KillOptions) error { return DefaultClient.Kill(opts) }

// Start starts a remove vm given by the id.
func Start(opts *StartOptions) (string, error) { return DefaultClient.Start(opts) }

// Stop stops a remove vm given by the id.
func Stop(opts *StopOptions) (string, error) { return DefaultClient.Stop(opts) }

// Wait polls on event stream given by the event identifier.
//
// It closes the returned channel as soon as stream state reaches
// 100% or an error occurs.
func Wait(event string) <-chan *stack.EventResponse {
	return DefaultClient.kloud().Wait(event)
}

// Show gets JMachine.meta value of a vm given by the identifier.
func Show(opts *ShowOptions) (map[string]interface{}, error) {
	return DefaultClient.Show(opts)
}

// Set sets JMachine.meta.key=value for a vm given by the identifier.
func Set(opts *SetOptions) error {
	return DefaultClient.Set(opts)
}
