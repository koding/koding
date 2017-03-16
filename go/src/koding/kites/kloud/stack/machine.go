package stack

import (
	"koding/kites/kloud/machine"

	"github.com/koding/kite"
)

// MachineListRequest represents a request value for "machine.list" method.
type MachineListRequest struct {
	MachineID string `json:"machineID"`
}

// MachineListResponse represents a response value from "machine.list" method.
type MachineListResponse struct {
	Machines []*machine.Machine `json:"machines"`
}

// CredentialList is a kite.Handler for "machine.list" kite method.
func (k *Kloud) MachineList(r *kite.Request) (interface{}, error) {
	var req MachineListRequest
	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	// We need to keep machine owners as well as skip unapproved shared machines
	// which shouldn't be visible until user approve them.
	f := &machine.Filter{
		ID:           req.MachineID,
		Username:     r.Username,
		Owners:       true,
		OnlyApproved: true,
	}

	machines, err := k.MachineClient.Machines(f)
	if err != nil {
		return nil, err
	}

	return MachineListResponse{Machines: machines}, nil
}
