package remote

import (
	"encoding/json"
	"fmt"
	"net"
	"net/url"
	"time"

	"koding/fuseklient"
	"koding/klient/remote/kitepinger"
	"koding/klient/storage"

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
	machines Machines

	// The time when the clients were cached at
	machinesCachedAt time.Time

	// The maximum duration that the clients can be cached for, relative to
	// the clientsCachedAt.
	machinesCacheMax time.Duration

	// If clients were cached within this duration value in the past, and
	// we encounter an error when attempting to getKites from Kontrol,
	// we simply return the kites to help the user UX.
	machinesErrCacheMax time.Duration

	// clientNamesCache is stored as map[machineIp]machineName
	//
	// TODO: Store names by kite id? Need to stop referencing by IP, for machines
	// on a single network.
	machineNamesCache map[string]string

	// A slice of local mounts (to list and unmount from, mainly).
	mounts Mounts

	log kite.Logger

	// mockable interfaces and types, used for testing and abstracting the environment
	// away.

	// unmountPath unmounts the given path via the system call, implemented usually
	// by fuseklient.Unmount
	unmountPath func(string) error
}

// NewRemote creates a new Remote instance.
func NewRemote(k *kite.Kite, log kite.Logger, s storage.Interface) *Remote {
	r := &Remote{
		localKite:           k,
		kitesGetter:         &KodingKite{Kite: k},
		storage:             s,
		log:                 log,
		machinesErrCacheMax: 5 * time.Minute,
		machinesCacheMax:    10 * time.Second,
		machineNamesCache:   map[string]string{},
		unmountPath:         fuseklient.Unmount,
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
func (r *Remote) GetKites() (Machines, error) {
	// If the clientsCachedAt value is within clientsCachedMax duration,
	// return them immediately.
	if len(r.machines) > 0 && r.machinesCachedAt.After(time.Now().Add(-r.machinesCacheMax)) {
		return r.machines, nil
	}

	kites, err := r.kitesGetter.GetKodingKites(&kiteprotocol.KontrolQuery{
		Name:     "klient",
		Username: r.localKite.Config.Username,
	})

	// If there is an error retreiving kites, check if our cache is too old.
	// We base this "too old" decision off of the clientsErrCacheMax value,
	// relative to the clientsCachedAt value.
	if err != nil {
		r.log.Error("Failed to getKites from Kontrol. Error: %s", err.Error())

		if r.machinesCachedAt.After(time.Now().Add(-r.machinesErrCacheMax)) {
			r.log.Warning(
				"Using clientsCache after failing to getKites. Cached %s ago",
				time.Now().Sub(r.machinesCachedAt),
			)
			return r.machines, err
		}

		return nil, err
	}

	// If any names are not yet created, we need to create missing names.
	var missingNames bool

	var clients Machines

	for _, k := range kites {
		// If the Id is the same, don't add it to the map
		if k.ID == r.localKite.Id {
			continue
		}

		host, err := r.hostFromClient(k.Client)
		if err != nil {
			return nil, err
		}

		// It's okay if we assign an empty string, no need to check for
		// the bool value. Note that it's important that we use two return
		// args, otherwise this would panic if the host doesn't exist.
		name, _ := r.machineNamesCache[host]

		if name == "" {
			missingNames = true
		}

		machine := NewMachine()
		machine.Client = k.Client
		machine.kitePinger = kitepinger.NewKitePinger(k.Client)
		machine.MachineLabel = k.MachineLabel
		machine.Teams = k.Teams
		machine.IP = host
		machine.Name = name
		clients = append(clients, machine)
	}

	r.machinesCachedAt = time.Now()
	r.machines = clients

	// Because our machine names are saved in the db, new IPs need to be
	// assigned a new unique name. We use createMissingNames to do that.
	if missingNames {
		r.createMissingNames()
	}

	return clients, nil
}

// GetKitesOrCache fetches kites from the kite cache no matter how old they are. If
// there is no cache, the kites are fetched from Kontrol like normal.
func (r *Remote) GetKitesOrCache() (Machines, error) {
	if len(r.machines) == 0 {
		return r.GetKites()
	}

	return r.machines, nil
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

// createMissingNames sets names to the machines as needed.
func (r *Remote) createMissingNames() error {
	// For ease of looking up, new ip names, we need to map existing
	// names to their respective ips, since they are stored in the
	// reverse.
	namesToIP := map[string]string{}
	for ip, name := range r.machineNamesCache {
		namesToIP[name] = ip
	}

	var cacheChanged bool
	for _, machine := range r.machines {
		// If the machine has a name, there's nothing needed.
		if machine.Name != "" {
			continue
		}

		// The name does not exist, so we need to find one for it. To do
		// that, loop through our available names, until one of them is
		// not already used.
		//
		// If we don't find it after len(machineNames) times, then we increment
		// the mod and try again.
		for mod := 0; machine.Name == ""; mod++ {
			for _, name := range machineNames {
				// Don't append an integer if it's mod zero
				if mod != 0 {
					name = fmt.Sprintf("%s%d", name, mod)
				}
				if _, ok := namesToIP[name]; !ok {
					machine.Name = name
					// Store the newly assigned name to this Ip
					namesToIP[name] = machine.IP
					// Break out of the inner machineNames loop, which will cause
					// the mod loop to not continue either, since machineName is
					// no longer empty.
					break
				}
			}
		}

		// Make sure to mark the cache as changed, so we can save it
		// after we're done.
		cacheChanged = true
		r.machineNamesCache[machine.IP] = machine.Name
	}

	// After we're done looping through our machines, check of machineName was written
	// to. if machineName was written to
	if cacheChanged {
		return r.saveMachinesNames()
	}

	return nil
}
