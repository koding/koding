package client

import (
	"context"
	"errors"
	"sync"
	"time"

	"koding/klient/machine"

	"github.com/koding/logging"
)

// DynamicAddrFunc is an adapter that allows to dynamically provide addresses
// from a given network. Error should be of ErrAddrNotFound type when provided
// network has no addresses.
type DynamicAddrFunc func(string) (machine.Addr, error)

// AddrSetFunc is a callback that can be used to cache addresses found by
// dynamic client.
type AddrSetFunc func(machine.Addr)

// Builder is an interface used to dynamically build remote machine clients.
type Builder interface {
	// Ping uses dynamic address provider to ping the machine. If error is nil,
	// this method should return address which was used to ping the machine.
	Ping(dynAddr DynamicAddrFunc) (machine.Status, machine.Addr, error)

	// Build builds new client which will connect to machine using provided
	// address.
	Build(ctx context.Context, addr machine.Addr) Client

	// IP lookups for IP address to machine pointed by provided argument. If
	// argument's network is already "ip", this method should be no-op. Non-nil
	// errors should be returned when it's not possible to find IP address using
	// given value.
	IP(addr machine.Addr) (machine.Addr, error)
}

// DynamicOpts are the options used to configure dynamic client.
type DynamicOpts struct {
	// AddrFunc is a factory for dynamic machine addresses.
	AddrFunc DynamicAddrFunc

	// AddrSetFunc will be called when dynamic client find new address.
	AddrSetFunc AddrSetFunc

	// Builder is a factory used to build clients.
	Builder Builder

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
func (opts *DynamicOpts) Valid() error {
	if opts.AddrFunc == nil {
		return errors.New("nil dynamic address function")
	}
	if opts.AddrSetFunc == nil {
		return errors.New("nil address set function")
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

// Dynamic is a client that may change it's endpoint address depending on client
// builder ping function status. It is safe to use this structure concurrently.
type Dynamic struct {
	opts DynamicOpts
	log  logging.Logger

	once sync.Once
	stop chan struct{} // channel used to close dynamic client.

	mu     sync.RWMutex
	c      Client             // current client.
	stat   machine.Status     // current connection status.
	cancel context.CancelFunc // function that can close current context.
}

// NewDynamic starts and returns a new DynamicClient instance. The caller should
// call Close when finished, in order to shut it down.
func NewDynamic(opts DynamicOpts) (*Dynamic, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	stop := make(chan struct{}, 1) // make Close function unblocked.

	dc := &Dynamic{
		opts: opts,
		stop: stop,
	}

	if opts.Log != nil {
		dc.log = opts.Log.New("monitor")
	} else {
		dc.log = machine.DefaultLogger.New("monitor")
	}

	dc.disconnected() // set disconnected client.
	go dc.cron()

	return dc, nil
}

// Status gets current client status. It may return zero value when client is
// disconnected.
func (dc *Dynamic) Status() machine.Status {
	dc.mu.RLock()
	stat := dc.stat
	dc.mu.RUnlock()

	return stat
}

// Client returns current client.
func (dc *Dynamic) Client() Client {
	dc.mu.RLock()
	c := dc.c
	dc.mu.RUnlock()

	return c
}

// Addr uses dynamic address function bound to client to obtain addresses.
func (dc *Dynamic) Addr(network string) (machine.Addr, error) {
	return dc.opts.AddrFunc(network)
}

// Close stops the dynamic client. After this function is called, client is
// in disconnected state and each contexts returned by it are closed.
func (dc *Dynamic) Close() error {
	dc.once.Do(func() {
		close(dc.stop)
	})

	return nil
}

func (dc *Dynamic) cron() {
	var (
		dynAddrTick = time.NewTicker(dc.opts.DynAddrInterval)
		pingTick    = time.NewTicker(dc.opts.PingInterval)
	)

	addr, ipAddr, err := machine.Addr{}, machine.Addr{}, error(nil)

	// Lookup for IP address and set if changed.
	setIP := func(a machine.Addr) {
		// Do not lookup tunneled connections.
		if _, err := dc.opts.AddrFunc("tunnel"); err == nil {
			return
		}

		ipA, err := dc.opts.Builder.IP(a)
		if err != nil || ipA.Network != "ip" {
			return
		}

		if ipAddr.Network == "ip" && ipA.Value == ipAddr.Value {
			// IP address did not change.
			return
		}

		dc.opts.AddrSetFunc(ipA)

		// Update current IP address.
		ipAddr = ipA
	}

	// tryUpdate uses client builder to ping the machine and updates dynamic
	// client if machine address changes.
	tryUpdate := func() {
		stat, a, e := dc.opts.Builder.Ping(dc.opts.AddrFunc)
		if e != nil {
			if err == nil {
				dc.log.Warning("Machine ping error: %s", e)
			}
			err = e
			return
		}
		err = nil

		setIP(a)

		if a.Network == addr.Network && a.Value == addr.Value {
			// Client address did not change.
			return
		}

		// Create new client.
		dc.log.Info("Reinitializing client with %s address: %s", a.Network, a.Value)
		ctx, cancel := context.WithCancel(context.Background())

		dc.mu.Lock()
		c := dc.opts.Builder.Build(ctx, a)
		// Update current address.
		addr = a

		if dc.cancel != nil {
			dc.cancel()
		}
		dc.c, dc.stat, dc.cancel = c, stat, cancel
		dc.mu.Unlock()
	}

	tryUpdate()
	for {
		select {
		case <-dynAddrTick.C:
			// Look address cache for new addresses. This does not require
			// pinging remote machines because it only checks current address
			// book state. Thus, it may be run more frequently than ping.
			a, err := dc.opts.AddrFunc(addr.Network)
			if err != nil || (a.Network == addr.Network && a.Value == addr.Value) {
				break
			}
			tryUpdate()
		case <-pingTick.C:
			// Ping remote machine directly in order to check its status.
			tryUpdate()
		case <-dc.stop:
			// Client was closed.
			dc.mu.Lock()
			dc.disconnected()
			dc.mu.Unlock()

			// Stop tickers.
			dynAddrTick.Stop()
			pingTick.Stop()
			return
		}
	}
}

// disconnected sets disconnected client.
func (dc *Dynamic) disconnected() {
	if dc.cancel != nil {
		dc.cancel()
	}

	ctx, cancel := context.WithCancel(context.Background())
	dc.cancel = cancel
	dc.c = NewDisconnected(ctx)
	dc.stat = machine.Status{}
}
