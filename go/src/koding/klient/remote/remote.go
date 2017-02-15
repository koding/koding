// The remote package contains the bulk of logic used by klientctl.
//
// The package naming refers to a local klient calling the remote klient.
// So `remote.mountFolder` would then mean that this klient mounts a
// remote folder to this klient's filesystem, and so on.
package remote

import (
	"encoding/json"
	"net"
	"net/url"
	"sync"
	"time"

	"koding/fuseklient"
	"koding/klient/remote/machine"
	"koding/klient/remote/mount"
	"koding/klient/storage"

	"github.com/koding/logging"

	"github.com/koding/kite"
	kiteprotocol "github.com/koding/kite/protocol"
)

const (
	// The key used to store machine names in the database, allowing machine names
	// to persist between Klient restarts.
	machineNamesStorageKey = "machine_names"

	// The max attempts that the Remote.restoreMounts() will loop. This should be
	// a very large number, and exists simply to allow testing to control the max
	// loops.
	//
	// 60*24*4 (5760) is roughly 4 days of repeated attempts at 1 minute pauses between
	// each attempt. Basically forever.
	defaultMaxRestoreAttempts = 60 * 24 * 4

	// The length in time that restoreMounts() will pause between each repeated attempt.
	defaultRestoreFailuresPause = time.Minute
)

// KodingKitesGetter is an interface to allow easily mockable getKodingKites calls.
// responses.
type KodingKitesGetter interface {
	GetKodingKites(*kiteprotocol.KontrolQuery) ([]*KodingClient, error)
}

// Remote handles a series of Klient methods for the local kite
// communication to remote klients. This includes listing, mounting,
// unmounting, and etc.
//
// Remote is typically called from a local machine, but it is best to
// think of it as *this* klient's interaction to *remote* klients.
//
// So `remote.mountFolder` would then mean that this klient mounts a
// remote folder to this klient's filesystem, and so on.
type Remote struct {
	// The local klient kite, used mainly to communicate to kontrol.
	localKite *kite.Kite

	// Typically this is just an instance of the local Kite, but can
	// also be easily mocked.
	kitesGetter KodingKitesGetter

	// A storage interface to store mount information
	storage storage.Interface

	// The remote machines that we have cached, along with their expirations.
	machines *machine.Machines

	// The time when the clients were cached at
	machinesCachedAt time.Time

	// The maximum duration that the clients can be cached for, relative to
	// the machinesCachedAt.
	machinesCacheMax time.Duration

	// If clients were cached within this duration value in the past, and
	// we encounter an error when attempting to getKites from Kontrol,
	// we simply return the kites to help the user UX.
	machinesErrCacheMax time.Duration

	// machineNamesCache is stored as map[machineIp]machineName
	//
	// TODO: Deprecate, and move this logic to *machine.Machine. It's left
	// here currently for backwards compatibility names that need to be loaded.
	machineNamesCache map[string]string

	// A slice of local mounts (to list and unmount from, mainly).
	mounts mount.Mounts

	log logging.Logger

	// getMachinesWithoutCache is responsible for actually creating locks, as
	// well as uniquely creating new machines. This lock ensures that creation
	// and updating of machines.
	getMachinesWithoutCacheLock sync.Mutex

	// The max attempts that the Remote.restoreMounts() will loop. This should be
	// a very large number, and exists simply to allow testing to control the max
	// loops.
	maxRestoreAttempts int

	// The length in time that restoreMounts() will pause between each repeated attempt.
	restoreFailuresPause time.Duration

	// mockable interfaces and types, used for testing and abstracting the environment
	// away.

	// unmountPath unmounts the given path via the system call, implemented usually
	// by fuseklient.Unmount
	unmountPath func(string) error

	// The mocked<methodName> fields provide a way to mock especially complex methods,
	// simplfying the testing requirements.
	mockedRestoreMount func(*mount.Mount) error

	// eventSub receives events when paths get unmounted
	eventSub chan<- *mount.Event
}

// RemoteOptions is used to create new Remote value.
type RemoteOptions struct {
	Kite     *kite.Kite          // local kite, used to communicate with Kontrol
	Log      kite.Logger         // used for logging
	Storage  storage.Interface   // persistence layer for Remote
	EventSub chan<- *mount.Event // receives events when path gets unmounted
}

// NewRemote creates a new Remote instance.
func NewRemote(opts *RemoteOptions) *Remote {
	// TODO: Improve this usage. Basically i want a proper koding/logging struct,
	// but we need to create it from somewhere. klient is always uses kite.Logger,
	// which **should** always be implemented by a koding/logging.Logger.. but in
	// the event that it's not, how do we handle it?
	kodingLog, ok := opts.Log.(logging.Logger)
	if !ok {
		opts.Log.Error(
			"Unable to convert koding/kite.Logger to koding/logging.Logger. Creating new logger",
		)
		kodingLog = logging.NewLogger("new-logger")
	}

	kodingLog = kodingLog.New("remote")
	// Setting the handler to debug, because various Remote methods allow a
	// debug option, and this saves us from having to set the handler level every time.
	// This only sets handler, not the actual loglevel.
	logging.DefaultHandler.SetLevel(logging.DEBUG)

	r := &Remote{
		localKite:            opts.Kite,
		kitesGetter:          &KodingKite{Kite: opts.Kite},
		storage:              opts.Storage,
		log:                  kodingLog,
		machinesErrCacheMax:  5 * time.Minute,
		machinesCacheMax:     10 * time.Second,
		machineNamesCache:    map[string]string{},
		unmountPath:          fuseklient.Unmount,
		machines:             machine.NewMachines(kodingLog, opts.Storage),
		maxRestoreAttempts:   defaultMaxRestoreAttempts,
		restoreFailuresPause: defaultRestoreFailuresPause,
		eventSub:             opts.EventSub,
	}

	return r
}

// Initialize handles loading mounts from storage, fixing, and any
// other "on start" style tasks for the Remote instance.
func (r *Remote) Initialize() error {
	r.log.Debug("Initializing Remote...")

	// Load the mounts from our storage
	if err := r.loadMounts(); err != nil {
		return err
	}

	// Load machine names from our storage
	if err := r.loadMachineNames(); err != nil {
		return err
	}

	// Load machines from storage
	if err := r.loadMachines(); err != nil {
		return err
	}

	if err := r.restoreMounts(); err != nil {
		return err
	}

	return nil
}

func (r *Remote) loadMachines() error {
	return r.machines.Load()
}

func (r *Remote) hostFromClient(k *kite.Client) (string, error) {
	u, err := url.Parse(k.URL)
	if err != nil {
		return "", err
	}

	host, _, err := net.SplitHostPort(u.Host)
	if err != nil {
		// we try if u.Host is just a host without a port and not
		// e.g. ill-formatted ipv6 address.
		_, _, e := net.SplitHostPort(net.JoinHostPort(u.Host, "80"))
		if e == nil {
			return u.Host, nil
		}

		return "", err
	}

	return host, nil
}

// GetKites fetches kites from Kontrol if no cached kites are found, while
// also filtering out the source (this) kite. If cached kites are found,
// they are returned instead.
//
// This helps ensure that calls to GetKites() can be spammed without
// ever reaching/harming Kontrol.
//
// If we are unable to get the kites from kontrol, but the cached
// results are not too old, we return the cached results rather than giving
// the user a bad UX.
func (r *Remote) GetMachines() (*machine.Machines, error) {
	log := r.log.New("GetMachines")

	// For readability
	haveMachines := r.machines.Count() > 0
	machinesCachedAgo := time.Now().Sub(r.machinesCachedAt)

	// If the machinesCachedAt value is within machinesCachedMax duration,
	// return them immediately.
	if haveMachines && machinesCachedAgo < r.machinesCacheMax {
		log.Debug("Getting machines via Cache only")
		return r.machines, nil
	}

	machines, err := r.GetMachinesWithoutCache()

	// If there was an error in retrieving machines without cache, but we are within
	// our cache err max, return the error. For a better description of why this exists,
	// see the r.machinesErrCacheMax docstring.
	if haveMachines && err != nil && machinesCachedAgo < r.machinesErrCacheMax {
		log.Warning(
			"Unable to get new machines from Koding. Using cached machines. err:%s", err,
		)
		return r.machines, nil
	}

	return machines, err
}

func (r *Remote) getKodingKites() ([]*KodingClient, error) {
	return r.kitesGetter.GetKodingKites(&kiteprotocol.KontrolQuery{
		Name:     "klient",
		Username: r.localKite.Config.Username,
	})
}

// GetMachinesWithoutCache gets the remote kites and returns machines without
// using the cache. Use this with caution!
//
// TODO: Discuss & decide what to do about errors during GetMachines. Chances
// are pretty good that we have machines, so we fail if we don't have to? Can we
// fail only if we have to? When do we have to fail? etc. ~LO
func (r *Remote) GetMachinesWithoutCache() (*machine.Machines, error) {
	log := r.log.New("GetMachinesWithoutCache")

	kites, err := r.getKodingKites()
	if err != nil {
		return nil, err
	}

	// Locking here, rather than at the beginning of the function, allows the
	// lock to only exist during the faster and racey operations within
	// GetMachinesWithoutCache. The only downside with locking here, rather
	// than at the top of the method, is that we're hitting Kontrol X times
	// during a race - but that is a UX/cost tradeoff, otherwise we would be
	// locking during the entire getKites request - potentially lagging the
	// UX and forcing the user to put up with X number of timeouts before
	// they get UX feedback.
	//
	// If Kontrol querying ends up too costly, we should lock at the top of the
	// func.
	r.getMachinesWithoutCacheLock.Lock()
	defer r.getMachinesWithoutCacheLock.Unlock()

	// If this ends up true, call Machines.Save() after the loop.
	var saveMachines bool

	// Loop through each of the kites, creating machines for any missing
	// kites or updating existing machines with the new kite info.
	// TODO: Use host-kiteId to locate machine.
	//
	// TODO: Make this loop retry any failed kites.
	for _, k := range kites {
		// If the kite is our local kite, skip it.
		if k.ID == r.localKite.Id {
			continue
		}

		if k.Client != nil {
			// Configure the kite klient
			configureKiteClient(k.Client)
		} else {
			// Should never happen
			log.Error("GetKodingKites returned a kite without a Client!")
		}

		existingMachine, err := r.matchMachineToKite(k.Client)

		// If the machine is not found, create a new one.
		if err == machine.ErrMachineNotFound {
			if err := r.createNewMachineFromKite(k, log); err != nil {
				log.Error("Unable to create a new machine from kite. err:%s", err)
				continue
			}

			// Set this so we know to save after the loop
			saveMachines = true
			// We've added our machine. Move onto the next.
			continue
		} else if err != nil {
			// Unknown error was returned from r.machines.GetByIP, move onto next
			// machine.
			log.Error("Unknown/unhandled error from machines.GetByIP. err:%s", err)
			continue
		}

		var shouldSave bool
		if err := existingMachine.CheckValid(); err == nil {
			shouldSave, err = r.updateValidMachineFromKite(k, existingMachine, log)
			if err != nil {
				log.Error("Unable to update existing machine from kite")
				continue
			}
		} else {
			shouldSave, err = r.restoreLoadedMachineFromKite(k, existingMachine, log)
			if err != nil {
				log.Error("Unable to restore loaded machine from kite")
				continue
			}
		}

		// If either a restored machine or existing machine has changed, set save
		// to true. It's done this way, so that a non-changed machine doesn't
		//
		// Note that we aren't assigning this in the above methods directly
		// because we don't want to set saveMachines to false if a machine
		// did not change.
		if shouldSave {
			saveMachines = true
		}
	}

	// Set our cached at values.
	r.machinesCachedAt = time.Now()

	// If any of the machines changed, save it
	if saveMachines {
		if err := r.machines.Save(); err != nil {
			log.Error("Unable to save machines. err:%s", err)
		}
	}

	return r.machines, nil
}

// matchMachineToKite iterates through the machines, returning the first one with
// a matching URL. If the machines URL is empty, it might be an old Machine from
// the DB, so it then extracts the Ip from the URL and attempts to match based
// on that.
//
// Devnote: that this method matches machines, but is not on the Machines struct
// because of the domain specific requirement (legacy machine matching). It felt
// out of place on the Machines struct.
func (r *Remote) matchMachineToKite(c *kite.Client) (*machine.Machine, error) {
	log := r.log.New("matchMachineToKite")

	for _, m := range r.machines.Machines() {
		// For legacy support, the machine may not have a filled URL field. If this is
		// the case, match it based on IP.
		//
		// Also, check this first - that way we don't match an empty kite url... not
		// like that should happen.
		if m.URL == "" {
			host, err := r.hostFromClient(c)
			if err != nil {
				log.Error("Unable to extract host from *kite.Client. err:%s", err)
				return nil, err
			}

			if m.IP == host {
				return m, nil
			}
		}

		if m.URL == c.URL {
			return m, nil
		}
	}

	return nil, machine.ErrMachineNotFound
}

func (r *Remote) createNewMachineFromKite(c *KodingClient, log logging.Logger) error {
	var host string
	host, err := r.hostFromClient(c.Client)
	if err != nil {
		log.Error("Unable to extract host from *kite.Client. err:%s", err)
		return err
	}

	// For backwards compatibility, check if the host already has a name
	// in the cache.
	//
	// If the name does not exist in the host the string will be empty, and
	// Machines.Add() will create a new unique name.
	//
	// If the string *does* exist then we use that, remove it from the map,
	// and save the map to avoid dealing with this next time.
	name, ok := r.machineNamesCache[host]
	if ok {
		log.Info(
			"Using legacy name, and removing it from database. name:%s, host:%s",
			name, host,
		)
		delete(r.machineNamesCache, host)
		// Should't bother exiting here, not a terrible error.. but not good, either.
		// Log it for knowledge, and move on.
		if err := r.saveMachinesNames(); err != nil {
			log.Error("Failed to save machine names. err:%s", err)
		}
	}

	// Name can be empty here, since Machines.Add() will handle creation
	// of the name.
	machineMeta := machine.MachineMeta{
		URL:          c.URL,
		IP:           host,
		Hostname:     c.Hostname,
		Username:     c.Username,
		Name:         name,
		MachineLabel: c.MachineLabel,
		Teams:        c.Teams,
	}

	newMachine, err := machine.NewMachine(machineMeta, r.log, c.Client)
	if err != nil {
		return err
	}

	if err = r.machines.Add(newMachine); err != nil {
		log.Error("Unable to Add new machine to *machine.Machines. err:%s", err)
		return err
	}

	return nil
}

// updateValidMachineFromKite takes an existing valid machine and updates it
// with any simple meta that might have changed. Ie, if you change a
// machines label on Koding, this method updates the Machine's label field.
func (r *Remote) updateValidMachineFromKite(c *KodingClient, validMachine *machine.Machine, log logging.Logger) (bool, error) {
	var metaChanged bool

	if validMachine.MachineLabel != c.MachineLabel {
		validMachine.MachineLabel = c.MachineLabel
		metaChanged = true
	}

	return metaChanged, nil
}

// restoreLoadedMachineFromKite takes an old loaded machine and applies meta
// changes to it, while also creating a valid machine instance with a proper
// transport/etc.
func (r *Remote) restoreLoadedMachineFromKite(c *KodingClient, loadedMachine *machine.Machine, log logging.Logger) (bool, error) {
	// metaChanged is our return value, which lets the caller know if any of the meta
	// for this machine changed from the given kite. If it does, the caller will
	// want to save the machines to the local db.
	var metaChanged bool

	host, err := r.hostFromClient(c.Client)
	if err != nil {
		log.Error("Unable to extract host from *kite.Client. err:%s", err)
		return false, err
	}

	// Get our old machine meta, loaded from the DB
	machineMeta := loadedMachine.MachineMeta
	if machineMeta.MachineLabel != c.MachineLabel {
		machineMeta.MachineLabel = c.MachineLabel
		metaChanged = true
	}

	if machineMeta.URL == "" && c.URL != "" {
		log.Warning("Machine missing MachineMeta.URL, updating it to %q", c.URL)
		machineMeta.URL = c.URL
		metaChanged = true
	}

	if machineMeta.IP == "" && host != "" {
		log.Warning("Machine missing MachineMeta.IP, updating it to %q", host)
		machineMeta.IP = host
		metaChanged = true
	}

	if machineMeta.Hostname != c.Hostname {
		machineMeta.Hostname = c.Hostname
		metaChanged = true
	}

	if machineMeta.Username != c.Username {
		machineMeta.Username = c.Username
		metaChanged = true
	}

	// Remove the machine, because we're going to be creating a new machine instance
	// below.
	err = r.machines.Remove(loadedMachine)
	if err != nil && err != machine.ErrMachineNotFound {
		log.Error("Unable to Remove old machine from *machine.Machines. err:%s", err)
		return false, err
	}

	restoredMachine, err := machine.NewMachine(machineMeta, r.log, c.Client)
	if err != nil {
		return false, err
	}

	// Add our newly created machine instance.
	if err = r.machines.Add(restoredMachine); err != nil {
		log.Error("Unable to Add new machine to *machine.Machines. err:%s", err)
		return false, err
	}

	return metaChanged, nil
}

// GetCacheOrMachines returns the existing machines without querying from
// kontrol if they exist. If there are no machines to return, kontrol is
// queried.
func (r *Remote) GetCacheOrMachines() (*machine.Machines, error) {
	if r.machines.Count() == 0 {
		return r.GetMachines()
	}

	return r.machines, nil
}

// GetMachine gets the machines from r.GetMachines(), and then returns the requested
// machine directly. If the machine is not found, a kontrol request is performed
// to possibly find the new machine. Meaning that this avoids requesting to kontrol
// if possible.
//
// If the given machine is not found, machine.MachineNotFound is returned.
func (r *Remote) GetMachine(name string) (*machine.Machine, error) {
	machines, err := r.GetCacheOrMachines()
	if err != nil {
		return nil, err
	}

	// If we encountered an error that is *not* machine not found, return the error.
	// We don't know what went wrong.
	m, err := machines.GetByName(name)
	if err != nil && err != machine.ErrMachineNotFound {
		return nil, err
	}

	if err == machine.ErrMachineNotFound {
		// At this point, we could not find the machine. So, do a normal kontrol request,
		// within our cache limit of course - to see if it is a new machine.
		machines, err = r.GetMachines()
		if err != nil {
			return nil, err
		}

		// Finally, now that we have as accurate information as possible, return our
		// machine or err
		return machines.GetByName(name)
	}

	return m, nil
}

// GetValidMachine calls GetMachine, and then checks if the machine is valid,
// returning it if it is.
//
// If the machine is not valid, we do a normal within-cache GetMachines request.
// If Kontrol returns our kite, this will populate our machine and we're
// good to go.
func (r *Remote) GetValidMachine(name string) (*machine.Machine, error) {
	machine, err := r.GetMachine(name)
	if err != nil {
		return nil, err
	}

	// If there are no problems, return it.
	if err := machine.CheckValid(); err == nil {
		return machine, nil
	}

	// If our machine was not valid, request new kites from kontrol (within cache
	// limits), and then check again if the machine is valid.
	//
	// We don't have to care about the response/error from GetMachines, because
	// we have our machine instance already, and if GetMachines errors, our Valid
	// check is still all that matters.
	r.GetMachines()

	// If Kontrol returned a kite for our machine, GetMachines will have populated it.
	// Check if it's now valid. Last attempt.
	if err := machine.CheckValid(); err != nil {
		return nil, err
	}

	return machine, nil
}

// GetValidDialedMachine calls GetValidMachine, and then dials it.
//
// Note that if you just want a dialed machine, but don't explicitly need a Valid
// machine, just get the machine and dial it yourself.
func (r *Remote) GetDialedMachine(name string) (*machine.Machine, error) {
	machine, err := r.GetValidMachine(name)
	if err != nil {
		return nil, err
	}

	if err := machine.DialOnce(); err != nil {
		return nil, err
	}

	return machine, nil
}

// loadMachineNames loads the machine name map from database.
func (r *Remote) loadMachineNames() error {
	// TODO: Figure out how to filter the "key not found error", so that
	// we don't ignore all errors.
	data, _ := r.storage.Get(machineNamesStorageKey)

	r.log.Debug("Loaded machine names from db, '%s'\n", data)

	// If there is no data, we have nothing to load.
	if data == "" {
		return nil
	}

	return json.Unmarshal([]byte(data), &r.machineNamesCache)
}

func (r *Remote) emit(ev *mount.Event) {
	if r.eventSub != nil {
		r.eventSub <- ev
	}
}

// saveMachineNames saves the machine name map to the database.
func (r *Remote) saveMachinesNames() error {
	data, err := json.Marshal(r.machineNamesCache)
	if err != nil {
		return err
	}

	sData := string(data)
	r.log.Debug("Saving machine names to db, '%s'\n", sData)

	err = r.storage.Set(machineNamesStorageKey, sData)
	if err != nil {
		return err
	}

	return nil
}

// configureKiteClient
func configureKiteClient(c *kite.Client) error {
	// Set reconnect.
	// https://github.com/koding/kite/blob/master/client.go#L300
	c.Reconnect = true

	return nil
}
