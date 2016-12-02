package machine

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/koding/logging"
)

// DynamicAddrFunc is an adapter that allows to dynamically provide addresses
// from a given network. Error should be of ErrAddrNotFound type when provided
// network has no addresses.
type DynamicAddrFunc func(string) (Addr, error)

// ClientBuilder is an interface used to dynamically build remote machine clients.
type ClientBuilder interface {
	// Ping uses dynamic address provider to ping the machine. If error is nil,
	// this method should return address which was used to ping the machine.
	Ping(dynAddr DynamicAddrFunc) (Status, Addr, error)

	// Build builds new client which will connect to machine using provided
	// address.
	Build(ctx context.Context, addr Addr) Client
}

// DynamicClientOpts are the options used to configure dynamic client.
type DynamicClientOpts struct {
	// AddrFunc is a factory for dynamic machine addresses.
	AddrFunc DynamicAddrFunc

	// Builder is a factory used to build clients.
	Builder ClientBuilder

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
func (opts *DynamicClientOpts) Valid() error {
	if opts.AddrFunc == nil {
		return errors.New("nil dynamic address function")
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

// DynamicClient is a client that may change it's endpoint address depending
// on client builder ping function status. It is safe to use this structure
// concurrently.
type DynamicClient struct {
	opts DynamicClientOpts
	log  logging.Logger

	once sync.Once
	stop chan struct{} // channel used to close dynamic client.

	mu     sync.RWMutex
	c      Client             // current client.
	stat   Status             // current connection status.
	ctx    context.Context    // context used in current client.
	cancel context.CancelFunc // function that can close current context.
}

// NewDynamicClient starts and returns a new DynamicClient instance. The caller
// should call Close when finished, in order to shut it down.
func NewDynamicClient(opts DynamicClientOpts) (*DynamicClient, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	stop := make(chan struct{}, 1) // make Close function unblocked.

	dc := &DynamicClient{
		opts: opts,
		stop: stop,
	}

	if opts.Log != nil {
		dc.log = opts.Log.New("monitor")
	} else {
		dc.log = logging.NewLogger("monitor")
	}

	dc.disconnected() // set disconnected client.
	go dc.cron()

	return dc, nil
}

// Status gets current client status. It may return zero value when client is
// disconnected.
func (dc *DynamicClient) Status() Status {
	dc.mu.RLock()
	stat := dc.stat
	dc.mu.RUnlock()

	return stat
}

// Client returns current client.
func (dc *DynamicClient) Client() Client {
	dc.mu.RLock()
	c := dc.c
	dc.mu.RUnlock()

	return c
}

// Context returns current client's context. If client change, returned context
// will be canceled. If there is no clients available in dynamic client. Already
// canceled context is returned.
func (dc *DynamicClient) Context() context.Context {
	dc.mu.RLock()
	defer dc.mu.RUnlock()

	if dc.ctx == nil {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		return ctx
	}

	return dc.ctx
}

// Close stops the dynamic client. After this function is called, client is
// in disconnected state and each contexts returned by it are closed.
func (dc *DynamicClient) Close() {
	dc.once.Do(func() {
		close(dc.stop)
	})
}

func (dc *DynamicClient) cron() {
	var (
		dynAddrTick = time.NewTicker(dc.opts.DynAddrInterval)
		pingTick    = time.NewTicker(dc.opts.PingInterval)
	)

	curr := Addr{}
	dc.tryUpdate(&curr)
	for {
		select {
		case <-dynAddrTick.C:
			// Look address cache for new addresses. This does not require
			// pinging remote machines because it only checks current address
			// book state. Thus, it may be run more frequently than ping.
			a, err := dc.opts.AddrFunc(curr.Net)
			if err != nil || (a.Net == curr.Net && a.Val == curr.Val) {
				break
			}
			dc.tryUpdate(&curr)
		case <-pingTick.C:
			// Ping remote machine directly in order to check its status.
			dc.tryUpdate(&curr)
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

// tryUpdate uses client builder to ping the machine and updates dynamic client
// if machine address changes.
func (dc *DynamicClient) tryUpdate(addr *Addr) {
	stat, a, err := dc.opts.Builder.Ping(dc.opts.AddrFunc)
	if err != nil {
		dc.log.Warning("Machine ping error: %s", err)
		return
	}

	if a.Net == addr.Net && a.Val == addr.Val {
		// Client address did not change.
		return
	}

	// Create new client.
	dc.log.Info("Reinitializing client with %s address: %s", a.Net, a.Val)
	ctx, cancel := context.WithCancel(context.Background())
	c := dc.opts.Builder.Build(ctx, a)

	// Update current address.
	*addr = a

	dc.mu.Lock()
	if dc.cancel != nil {
		dc.cancel()
	}
	dc.c, dc.stat, dc.ctx, dc.cancel = c, stat, ctx, cancel
	dc.mu.Unlock()
}

// disconnected sets disconnected client.
func (dc *DynamicClient) disconnected() {
	if dc.cancel != nil {
		dc.cancel()
	}

	dc.c = DisconnectedClient{}
	dc.stat = Status{}
	dc.ctx = nil
	dc.cancel = nil
}
