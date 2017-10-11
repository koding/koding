package machinegroup

import (
	"errors"
	"sync"
	"sync/atomic"
	"time"

	"koding/kites/tunnelproxy/discover"
	"koding/klient/machine"
	"koding/klient/machine/client"
	"koding/klient/machine/machinegroup/addresses"
	"koding/klient/machine/machinegroup/aliases"
	"koding/klient/machine/machinegroup/clients"
	"koding/klient/machine/machinegroup/idset"
	"koding/klient/machine/machinegroup/metadata"
	"koding/klient/machine/machinegroup/mounts"
	"koding/klient/machine/machinegroup/syncs"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/notify"
	msync "koding/klient/machine/mount/sync"
	"koding/klient/storage"

	"github.com/koding/logging"
)

// Options are the options used to configure machine group.
type Options struct {
	// Discover is used to resolve address if klient connection is tunneled. If
	// nil, default discover client will be used.
	Discover *discover.Client

	// Storage defines the storage where machine group can save its state. If
	// nil, no storage will be used.
	Storage storage.ValueInterface

	// Builder is a factory used to build clients.
	Builder client.Builder

	// NotifyBuilder defines a factory used to build FS notification objects.
	NotifyBuilder notify.Builder

	// SyncBuilder defines a factory used to build file synchronization objects.
	SyncBuilder msync.Builder

	// DynAddrInterval indicates how often dynamic client should look for new
	// machine addresses.
	DynAddrInterval time.Duration

	// PingInterval indicates how often dynamic client should ping external
	// machine.
	PingInterval time.Duration

	// WorkDir is a working directory that will be used by mount syncs object.
	WorkDir string

	// Log is used for logging. If nil, default logger will be created.
	Log logging.Logger
}

// Valid checks if provided options are correct.
func (opts *Options) Valid() error {
	if opts == nil {
		return errors.New("nil group options provided")
	}
	if opts.Builder == nil {
		return errors.New("client builder is nil")
	}
	if opts.NotifyBuilder == nil {
		return errors.New("file system notification builder is nil")
	}
	if opts.SyncBuilder == nil {
		return errors.New("synchronization builder is nil")
	}
	if opts.DynAddrInterval == 0 {
		return errors.New("dynamic address check interval is not set")
	}
	if opts.PingInterval == 0 {
		return errors.New("ping interval is not set")
	}
	if opts.WorkDir == "" {
		return errors.New("working directory cannot be empty")
	}

	return nil
}

// Group allows to manage one or more machines.
type Group struct {
	nb  notify.Builder
	sb  msync.Builder
	log logging.Logger

	client  *clients.Clients
	address addresses.Addresser
	alias   aliases.Aliaser
	meta    metadata.Metadater
	mount   mounts.Mounter

	sync     *syncs.Syncs
	discover *discover.Client
}

// New creates a new Group object.
func New(opts *Options) (*Group, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	// Initialize group with builders.
	g := &Group{
		nb: opts.NotifyBuilder,
		sb: opts.SyncBuilder,
	}

	// Add logger to group.
	if opts.Log != nil {
		g.log = opts.Log.New("machines")
	} else {
		g.log = machine.DefaultLogger.New("machines")
	}

	// Use default discover client when not set.
	if opts.Discover != nil {
		g.discover = opts.Discover
	} else {
		g.discover = discover.NewClient()
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

	// Create syncs object for synced mounts.
	syncsOpts := syncs.Options{
		WorkDir: opts.WorkDir,
		Log:     g.log,
	}
	g.sync, err = syncs.New(syncsOpts)
	if err != nil {
		g.log.Critical("Cannot create mount syncer: %s", err)
		return nil, err
	}

	// Add default components.
	g.address = addresses.New()
	g.alias = aliases.New()
	g.meta = metadata.New()
	g.mount = mounts.New()
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

	// Try to add storage for Metadata.
	if meta, err := metadata.NewCached(opts.Storage); err != nil {
		g.log.Warning("Cannot load metadata cache: %s", err)
	} else {
		g.meta = meta
	}

	// Try to add storage for Mounts
	if mount, err := mounts.NewCached(opts.Storage); err != nil {
		g.log.Warning("Cannot load mounts cache: %s", err)
	} else {
		g.mount = mount
	}

	// Start memory workers.
	g.bootstrap()

	return g, nil
}

// Close closes Group's underlying clients.
func (g *Group) Close() error {
	return nonil(g.sync.Close(), g.client.Close())
}

// bootstrap initializes machine group workers and checks loaded data for
// consistency.
func (g *Group) bootstrap() {
	var (
		aliasIDs   = g.alias.Registered()
		metaIDs    = g.meta.Registered()
		addressIDs = g.address.Registered()
		mountsIDs  = g.mount.Registered()
	)

	// Report and generate missing aliases.
	noAliases := idset.Union(
		idset.Diff(addressIDs, aliasIDs), // missing aliases for addresses.
		idset.Diff(mountsIDs, aliasIDs),  // missing aliases for mounts.
	)

	for _, id := range noAliases {
		g.log.Warning("Missing alias for %s, regenerating...", id)
		alias, err := g.alias.Create(id)
		if err != nil {
			g.log.Error("Cannot create alias for %s: %s", id, err)
		}

		g.log.Info("Created alias for %s, %s", id, alias)
	}

	// Save newly generated aliases.
	if len(noAliases) != 0 {
		if cache, ok := g.alias.(machine.Cacher); ok {
			if err := cache.Cache(); err != nil {
				g.log.Warning("Regenerated aliases were not cached: %v", err)
			}
		}
	}

	// Start clients for all available addresses and for mounts even if they
	// may have no address, they will need disconnected client.
	for _, id := range idset.Union(addressIDs, mountsIDs) {
		if err := g.client.Create(id, g.dynamicAddr(id), g.addrSet(id)); err != nil {
			g.log.Error("Cannot create client for %s: %s", id, err)
		}
	}

	clientsIDs := g.client.Registered()
	allIds := idset.Union(idset.Union(aliasIDs, addressIDs), idset.Union(metaIDs, mountsIDs))

	g.log.Info("Detected %d machines, started %d clients.", len(allIds), len(clientsIDs))

	// Start synchronization of all mounts even if some of them have invalid
	// clients.
	g.mountSync(mountsIDs)
}

// mountsSync tries to add all available mounts to mount syncer.
func (g *Group) mountSync(ids machine.IDSlice) {
	mountsN, errN := 0, int64(0)
	var wg sync.WaitGroup
	for _, id := range ids {
		mountMap, err := g.mount.All(id)
		if err != nil {
			g.log.Warning("Cannot get mounts form machine %s: %s", id, err)
			continue
		}

		mountsN += len(mountMap)
		wg.Add(len(mountMap))
		for mountID, m := range mountMap {
			id, mountID, m := id, mountID, m // Capture range variable.
			go func() {
				defer wg.Done()

				addReq := &syncs.AddRequest{
					MountID:       mountID,
					Mount:         m,
					NotifyBuilder: g.nb,
					SyncBuilder:   g.sb,
					ClientFunc:    g.dynamicClient(mountID),
					SSHFunc:       g.dynamicSSH(id),
				}

				if err := g.sync.Add(addReq); err != nil {
					atomic.AddInt64(&errN, 1)
					g.log.Error("Cannot start synchronization for mount %s: %s", mountID, err)
					return
				}

				sc, err := g.sync.Sync(mountID)
				if err != nil {
					panic("created mount " + m.String() + " does not exist")
				}
				sc.UpdateIndex()
			}()
		}
	}

	wg.Wait()
	g.log.Info("Syncing %d mounts of %d machines. Failed %d", mountsN-int(errN), len(ids), errN)
}

// dynamicAddr creates dynamic address functor for the given machine.
func (g *Group) dynamicAddr(id machine.ID) client.DynamicAddrFunc {
	return func(network string) (machine.Addr, error) {
		return g.address.Latest(id, network)
	}
}

// addrSet creates a functor that allows to update machine address book.
func (g *Group) addrSet(id machine.ID) client.AddrSetFunc {
	return func(addr machine.Addr) {
		a, err := g.address.Latest(id, addr.Network)
		if err != nil && err != machine.ErrAddrNotFound {
			return
		}

		if err == machine.ErrAddrNotFound {
			g.address.Add(id, addr)
			return
		}

		// BoltDB optimization. No need to add address when its latest value is
		// already equal to the one that this function tries to set.
		if a.Value == addr.Value {
			return
		}

		g.address.Add(id, addr)
	}
}

// dynamicClient creates dynamic client functor that is used for mount sync
// connections.
func (g *Group) dynamicClient(mountID mount.ID) client.DynamicClientFunc {
	return func() (client.Client, error) {
		id, err := g.mount.MachineID(mountID)
		if err != nil {
			return nil, err
		}

		return g.client.Client(id)
	}
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
