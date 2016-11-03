package stack

import (
	"koding/kites/kloud/machine"

	"github.com/koding/kite"
)

type MachineListRequest struct {
	Provider string `json:"provider,omitempty"`
	Team     string `json:"team,omitempty"`
}

type MachineListResponse struct {
	Machines []*machine.Machine `json:"machines"`
}

func (k *Kloud) MachineList(r *kite.Request) (interface{}, error) {
	var req MachineListRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	k.Log.Info("List request: %#v", req)

	f := &machine.Filter{
		Username: r.Username,
	}

	machines, err := k.MachineClient.Machines(f)
	if err != nil {
		return nil, err
	}

	return MachineListResponse{
		Machines: machines,
	}, nil
}
