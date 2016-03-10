package remote

import (
	"koding/klient/remote/machine"

	"github.com/koding/kite"
)

type kiteInfo struct {
	// The Ip of the running machine
	IP string

	// The human friendly "name" of the machine.
	VMName string

	// The machine label, as seen by the koding ui
	MachineLabel string

	// The team names for the remote machine, if any
	Teams []string

	// Kite identifying values. For reference, see:
	// https://github.com/koding/kite/blob/master/protocol/protocol.go#L18
	Name        string
	ID          string
	Environment string
	Region      string
	Version     string
	Hostname    string
	Username    string

	Mounts       []mountInfo
	MountedPaths []string
}

type mountInfo struct {
	RemotePath string `json:"remotePath"`
	LocalPath  string `json:"localPath"`
}

// ListHandler (remote.list) lists the kites that are registered with Kontrol.
// Note that this kite is not returned.
func (r *Remote) ListHandler(req *kite.Request) (interface{}, error) {
	var (
		machines []*machine.Machine
		err      error
		params   struct {
			UseCache bool `json:"useCache"`
		}
	)

	if req.Args != nil {
		if err := req.Args.One().Unmarshal(&params); err != nil {
			r.log.Warning(
				"remote.list: Failed to unmarshal args, ignoring args. err:%s", err,
			)
		}
	}

	//	if params.UseCache {
	//		machines, err = r.GetOrCache()
	//	} else {
	// Temporary syntax to use existing vars.
	machineStruct, err := r.GetMachines()
	machines = machineStruct.Machines()
	//	}

	if err != nil {
		r.log.Error(
			"Failed getting kites. useCache:%t, err:%s",
			params.UseCache, err,
		)
		return nil, err
	}

	infos := make([]kiteInfo, len(machines))

	for i, machine := range machines {
		k := kiteInfo{
			Environment:  machine.Client.Environment,
			Hostname:     machine.Client.Hostname,
			ID:           machine.Client.ID,
			IP:           machine.IP,
			VMName:       machine.Name,
			Region:       machine.Client.Region,
			Username:     machine.Client.Username,
			Version:      machine.Client.Version,
			MountedPaths: []string{},
			MachineLabel: machine.MachineLabel,
			Teams:        machine.Teams,
		}

		m, ok := r.mounts.FindByName(machine.Name)
		if ok {
			k.Mounts = []mountInfo{mountInfo{
				RemotePath: m.RemotePath,
				LocalPath:  m.LocalPath,
			}}
			k.MountedPaths = append(k.MountedPaths, m.LocalPath)
		}

		infos[i] = k
	}

	return infos, nil
}
