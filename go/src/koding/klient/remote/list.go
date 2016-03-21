package remote

import (
	"koding/klient/remote/machine"
	"koding/klient/remote/restypes"

	"github.com/koding/kite"
)

// ListHandler (remote.list) lists the kites that are registered with Kontrol.
// Note that this kite is not returned.
func (r *Remote) ListHandler(req *kite.Request) (interface{}, error) {
	log := r.log.New("listHandler")

	var (
		machines *machine.Machines
		err      error
		params   struct {
			UseCache bool `json:"useCache"`
		}
	)

	if req.Args != nil {
		if err := req.Args.One().Unmarshal(&params); err != nil {
			log.Warning("Failed to unmarshal args, ignoring args. err:%s", err)
		}
	}

	if params.UseCache {
		machines, err = r.GetCacheOrMachines()
	} else {
		machines, err = r.GetMachines()
	}

	if err != nil {
		log.Error("Failed getting kites. useCache:%t, err:%s", params.UseCache, err)
		return nil, err
	}

	infos := make([]restypes.ListMachineInfo, machines.Count())
	for i, machine := range machines.Machines() {
		info := restypes.ListMachineInfo{
			IP:           machine.IP,
			VMName:       machine.Name,
			MountedPaths: []string{},
			MachineLabel: machine.MachineLabel,
			Teams:        machine.Teams,
		}

		info.MachineStatus = getMachineStatus(machine)

		if machine.Client != nil {
			info.Environment = machine.Client.Environment
			info.Hostname = machine.Client.Hostname
			info.ID = machine.Client.ID
			info.Region = machine.Client.Region
			info.Username = machine.Client.Username
			info.Version = machine.Client.Version
		}

		m, ok := r.mounts.FindByName(machine.Name)
		if ok {
			info.Mounts = []restypes.ListMountInfo{restypes.ListMountInfo{
				RemotePath:     m.RemotePath,
				LocalPath:      m.LocalPath,
				LastMountError: m.LastMountError,
			}}
			info.MountedPaths = append(info.MountedPaths, m.LocalPath)
		}

		infos[i] = info
	}

	return infos, nil
}

// getMachineStatus returns a machine status for the given machine, based on
// the given kitepingers/etc.
func getMachineStatus(machine *machine.Machine) restypes.MachineStatus {
	// Storing some vars for readability
	var (
		// If we have a kitepinger, and are actively pinging, we show
		// connected/disconnected
		useConnected bool

		// If we are not showing connected/disconnected, but we are pinging http,
		// use online/offline
		useOnline bool

		isConnected bool
		isOnline    bool
	)

	if machine.KiteTracker != nil {
		useConnected = machine.KiteTracker.IsPinging()
		isConnected = machine.KiteTracker.IsConnected()
	}

	if machine.HTTPTracker != nil {
		isOnline = machine.HTTPTracker.IsPinging()
		useOnline = machine.HTTPTracker.IsConnected()
	}

	switch {
	case useConnected && isConnected:
		return restypes.MachineConnected
	case useConnected && !isConnected:
		return restypes.MachineDisconnected
	case useOnline && isOnline:
		return restypes.MachineOnline
	default:
		return restypes.MachineOffline
	}
}
