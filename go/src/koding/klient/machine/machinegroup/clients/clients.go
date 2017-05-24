package clients

import (
	"errors"
	"sync"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client"

	"github.com/koding/logging"
)

// ClientsOpts are the options used to configure set of dynamic clients.
type ClientsOpts struct {
	// Builder is a factory used to build clients.
	Builder client.Builder

	// DynAddrInterval indicates how often dynamic client should pull address
	// function looking for new addresses.
	DynAddrInterval time.Duration

	// PingInterval indicates how often dynamic client should ping external
	// machine.
	PingInterval time.Duration

	// Log is used for logging. If nil, default logger will be created.
	Log logging.Logger
}

// Valid checks if provided options are correct.
func (opts *ClientsOpts) Valid() error {
	if opts == nil {
		return errors.New("nil clients options provided")
	}
	if opts.Builder == nil {
		return errors.New("nil client builder")
	}
	if opts.DynAddrInterval == 0 {
		return errors.New("dynamic address check interval is not set")
	}
	if opts.PingInterval == 0 {
		return errors.New("ping interval is not set")
	}

	return nil
}

// Clients is a set of dynamic clients binded to unique machine ID.
type Clients struct {
	builder         client.Builder
	dynAddrInterval time.Duration
	pingInterval    time.Duration

	log logging.Logger

	mu sync.RWMutex
	m  map[machine.ID]*client.Dynamic
}

// New creates a new Clients object.
func New(opts *ClientsOpts) (*Clients, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	c := &Clients{
		builder:         opts.Builder,
		dynAddrInterval: opts.DynAddrInterval,
		pingInterval:    opts.PingInterval,
		log:             opts.Log,
		m:               make(map[machine.ID]*client.Dynamic),
	}

	if c.log == nil {
		c.log = machine.DefaultLogger
	}

	return c, nil
}

// Create generates a new dynamic client for a given machine. If machine client
// already exists, this function is no-op.
func (c *Clients) Create(id machine.ID, dynAddr client.DynamicAddrFunc, addrSet client.AddrSetFunc) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if _, ok := c.m[id]; ok {
		return nil
	}

	dc, err := client.NewDynamic(client.DynamicOpts{
		AddrFunc:        dynAddr,
		AddrSetFunc:     addrSet,
		Builder:         c.builder,
		DynAddrInterval: c.dynAddrInterval,
		PingInterval:    c.pingInterval,
		Log:             c.log.New(string(id)),
	})
	if err != nil {
		return err
	}

	c.m[id] = dc

	return nil
}

// Drop closes and removes dynamic client binded to provided machine ID.
func (c *Clients) Drop(id machine.ID) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	return c.drop(id)
}

func (c *Clients) drop(id machine.ID) error {
	dc, ok := c.m[id]
	if !ok {
		return nil
	}
	delete(c.m, id)

	dc.Close()
	return nil
}

// Close closes and drops all dynamic clients registered to Clients.
func (c *Clients) Close() (err error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	for id := range c.m {
		if e := c.drop(id); e != nil && err == nil {
			err = e
		}
	}

	return err
}

// Status gets machine dynamic client status. It may return nil error and zero
// value when client is disconnected. machine.ErrMachineNotFound is returned
// when there are no clients for a given machine ID.
func (c *Clients) Status(id machine.ID) (machine.Status, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	dc, ok := c.m[id]
	if !ok {
		return machine.Status{}, machine.ErrMachineNotFound
	}

	return dc.Status(), nil
}

// Client returns the current clients of provided machine.
// machine.ErrMachineNotFound is returned when there are no clients for a given
// machine ID.
func (c *Clients) Client(id machine.ID) (client.Client, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	dc, ok := c.m[id]
	if !ok {
		return nil, machine.ErrMachineNotFound
	}

	return dc.Client(), nil
}

// Registered returns all machines that are stored in this object.
func (c *Clients) Registered() machine.IDSlice {
	c.mu.RLock()
	defer c.mu.RUnlock()

	registered := make(machine.IDSlice, 0, len(c.m))
	for id := range c.m {
		registered = append(registered, id)
	}

	return registered
}
