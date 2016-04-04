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
			Hostname:     machine.Hostname,
			MountedPaths: []string{},
			MachineLabel: machine.MachineLabel,
			Teams:        machine.Teams,
		}

		// Set the machines status and message.
		info.MachineStatus, info.StatusMessage = machine.GetStatus()

		m, ok := r.mounts.FindByName(machine.Name)
		if ok {
			info.Mounts = []restypes.ListMountInfo{restypes.ListMountInfo{
				RemotePath: m.RemotePath,
				LocalPath:  m.LocalPath,
			}}
			info.MountedPaths = append(info.MountedPaths, m.LocalPath)
		}

		infos[i] = info
	}

	return infos, nil
}
