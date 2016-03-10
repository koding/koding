package remote

import (
	"encoding/json"
	"net"
	"net/url"
	"time"

	"koding/fuseklient"
	"koding/klient/remote/kitepinger"
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
)

// 15 uniquely identifiable names to be used to identify machines.
var machineNames = []string{
	"apple", "orange", "banana", "grape", "coconut", "peach", "mango", "date",
	"kiwi", "lemon", "squash", "jackfruit", "raisin", "tomato", "quince",
}

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

	// mockable interfaces and types, used for testing and abstracting the environment
	// away.

	// unmountPath unmounts the given path via the system call, implemented usually
	// by fuseklient.Unmount
	unmountPath func(string) error
}

// NewRemote creates a new Remote instance.
func NewRemote(k *kite.Kite, log kite.Logger, s storage.Interface) *Remote {

	// TODO: Improve this usage. Basically i want a proper koding/logging struct,
	// but we need to create it from somewhere. klient is always uses kite.Logger,
	// which **should** always be implemented by a koding/logging.Logger.. but in
	// the event that it's not, how do we handle it?
	kodingLog, ok := log.(logging.Logger)
	if !ok {
		log.Error(
			"Unable to convert koding/kite.Logger to koding/logging.Logger. Creating new logger",
		)
		kodingLog = logging.NewLogger("new-logger")
	}

	kodingLog = kodingLog.New("remote")

	r := &Remote{
		localKite:           k,
		kitesGetter:         &KodingKite{Kite: k},
		storage:             s,
		log:                 kodingLog,
		machinesErrCacheMax: 5 * time.Minute,
		machinesCacheMax:    10 * time.Second,
		machineNamesCache:   map[string]string{},
		unmountPath:         fuseklient.Unmount,
		machines:            machine.NewMachines(kodingLog, s),
	}

	return r
}

// Initialize handles loading mounts from storage, fixing, and any
// other "on start" style tasks for the Remote instance.
func (r *Remote) Initialize() error {
	r.log.Debug("Initializing Remote...")

	// Load the mounts from our storage
	err := r.loadMounts()
	if err != nil {
		return err
	}

	// Load machine names from our storage
	err = r.loadMachineNames()
	if err != nil {
		return err
	}

	err = r.restoreMounts()
	if err != nil {
		return err
	}

	return nil
}

func (r *Remote) hostFromClient(k *kite.Client) (string, error) {
	u, err := url.Parse(k.URL)
	if err != nil {
		return "", err
	}

	host, _, err := net.SplitHostPort(u.Host)
	if err != nil {
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
	// If the machinesCachedAt value is within machinesCachedMax duration,
	// return them immediately.
	if r.machines.Count() > 0 && r.machinesCachedAt.After(time.Now().Add(-r.machinesCacheMax)) {
		return r.machines, nil
	}

	return r.GetMachinesWithoutCache()
}

func (r *Remote) getKodingKites() ([]*KodingClient, error) {
	return r.kitesGetter.GetKodingKites(&kiteprotocol.KontrolQuery{
		Name:     "klient",
		Username: r.localKite.Config.Username,
	})
}

// GetMachinesWithoutCache gets the remote kites and returns machines without
// using the cache. Use this with caution!
func (r *Remote) GetMachinesWithoutCache() (*machine.Machines, error) {
	log := r.log.New("GetMachines")

	kites, err := r.getKodingKites()
	if err != nil {
		log.Warning(
			"Unable to get new machines from Koding. Using existing machines. err:%s", err,
		)
		return r.machines, nil
	}

	// If this ends up true, call Machines.Save() after the loop.
	var saveMachines bool

	// Loop through each of the kites, creating machines for any missing
	// kites or updating existing machines with the new kite info.
	// TODO: Use host-kiteId to locate machine.
	for _, k := range kites {
		var host string
		host, err = r.hostFromClient(k.Client)
		if err != nil {
			log.Error("Unable to extract host from *kite.Client. err:%s", err)
			break
		}

		var existingMachine *machine.Machine
		existingMachine, err = r.machines.GetByIP(host)

		// If the machine is not found, create a new one.
		if err == machine.ErrMachineNotFound {
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
				log.Info("Using legacy name, and removing it from database.")
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
				Name:         name,
				MachineLabel: k.MachineLabel,
				IP:           host,
				Teams:        k.Teams,
			}

			err = r.machines.Add(machine.NewMachine(
				machineMeta, r.log, k.Client, kitepinger.NewKitePinger(k.Client),
			))
			if err != nil {
				log.Error("Unable to Add new machine to *machine.Machines. err:%s", err)
				break
			}

			// Set this so we know to save after the loop
			saveMachines = true

			// We've added our machine. Move onto the next.
			continue
		}

		// Unknown error, return it.
		if err != nil {
			break
		}

		// Update the label. If they're the same, the update has no affect.
		if existingMachine.MachineLabel != k.MachineLabel {
			log.Debug(
				"existing MachineLabel %q doesn't match remote kite's MachineLabel %q. Updating.",
				existingMachine.MachineLabel, k.MachineLabel,
			)
			existingMachine.MachineLabel = k.MachineLabel

			// Set this so we know to save after the loop
			saveMachines = true
		}

		// In the event that this machine was previously offline, or if klient was
		// restarted, the machine will be lacking many instance fields. If we have
		// a kite for the machine, populate those fields so the machine is
		// usable again.
		if existingMachine.Client == nil {
			log.Debug("existingMachine missing *kite.Client, adding..")
			existingMachine.Client = k.Client
		}

		if existingMachine.Transport == nil {
			log.Debug("existingMachine missing machine.Transport, adding..")
			existingMachine.Transport = k.Client
		}

		if existingMachine.Log == nil {
			log.Debug("existingMachine missing logging.Logger, adding..")
			existingMachine.Log = machine.MachineLogger(existingMachine.MachineMeta, log)
		}

		if existingMachine.KitePinger == nil {
			log.Debug("existingMachine missing kitepinger.KitePinger, adding..")
			existingMachine.KitePinger = kitepinger.NewKitePinger(k.Client)
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

// GetCacheOrMachines returns the existing machines without querying from
// kontrol if they exist. If there are no machines to return, kontrol is
// queried.
func (r *Remote) GetCacheOrMachines() (*machine.Machines, error) {
	if r.machines.Count() == 0 {
		return r.GetMachines()
	}

	return r.machines, nil
}

// GetMachine gets the machines from r.GetKites(), and then returns the requested
// machine directly. For information on whether or not this uses a cache, see
// r.GetKites() docstring.
//
// If the given machine is not found, machine.MachineNotFound is returned.
func (r *Remote) GetMachine(name string) (*machine.Machine, error) {
	machines, err := r.GetMachines()
	if err != nil {
		return nil, err
	}

	return machines.GetByName(name)
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
