package machinegroup

import (
	"errors"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup/addresses"
	"koding/klient/machine/machinegroup/aliases"
	"koding/klient/machine/machinegroup/clients"
	"koding/klient/storage"

	"github.com/koding/logging"
)

// GroupOpts are the options used to configure machine group.
type GroupOpts struct {
	// Storage defines the storage where machine group can save its state. If
	// nil, no storage will be used.
	Storage storage.ValueInterface

	// Builder is a factory used to build clients.
	Builder machine.ClientBuilder

	// DynAddrInterval indicates how often dynamic client should look for new
	// machine addresses.
	DynAddrInterval time.Duration

	// PingInterval indicates how often dynamic client should ping external
	// machine.
	PingInterval time.Duration

	// Log is used for logging. If nil, default logger will be created.
	Log logging.Logger
}

// Valid checks if provided options are correct.
func (opts *GroupOpts) Valid() error {
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

// Machines allows to manage one or more machines.
type Group struct {
	log logging.Logger

	client  *clients.Clients
	address addresses.Addresser
	alias   aliases.Aliaser
}

// New creates a new Group object.
func New(opts GroupOpts) (*Group, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	g := &Group{}

	// Add logger to group.
	if opts.Log != nil {
		g.log = opts.Log.New("machines")
	} else {
		g.log = logging.NewLogger("machines")
	}

	// Create dynamic clients.
	var err error
	g.client, err = clients.New(&clients.ClientsOpts{
		Builder:         opts.Builder,
		DynAddrInterval: opts.DynAddrInterval,
		PingInterval:    opts.PingInterval,
		Log:             g.log,
	})
	if err != nil {
		g.log.Critical("Cannot create machine monitor: %s", err)
		return nil, err
	}

	// Add default components.
	g.address = addresses.New()
	g.alias = aliases.New()
	if opts.Storage == nil {
		return g, nil
	}

	// Try to add storage for Addresses.
	if address, err := addresses.NewCached(opts.Storage); err != nil {
		g.log.Warning("Cannot load addresses cache: %s", err)
	} else {
		g.address = address
	}

	// Try to add storage for Aliases.
	if alias, err := aliases.NewCached(opts.Storage); err != nil {
		g.log.Warning("Cannot load aliases cache: %s", err)
	} else {
		g.alias = alias
	}

	return g, nil
}
