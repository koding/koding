package machinegroup

import (
	"errors"

	"koding/klient/machine"
)

// IDRequest defines machine group ID request.
type IDRequest struct {
	// Identifier is a string that identifiers remote machine.
	Identifier string `json:"identifier"`
}

// IDResponse defines machine group ID response.
type IDResponse struct {
	// ID is a unique identifier for the remote machine.
	ID machine.ID `json:"id"`
}

// ID gets machine ID from provided identifier. This method looks up machine
// aliases and machine IP addresses. Supported identifiers are:
//  - machine full ID string.
//  - machine alias.
//  - machine IP address.
func (g *Group) ID(req *IDRequest) (*IDResponse, error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	// If machine ID or machine alias, Aliases will have it.
	if id, err := g.alias.MachineID(req.Identifier); err == nil {
		return &IDResponse{ID: id}, nil
	}

	// Look up for machine IP. This have races, since machine can be added or
	// deleted in the meantime.
	if id, err := g.address.MachineID(machine.Addr{
		Network: "ip",
		Value:   req.Identifier,
	}); err == nil {
		return &IDResponse{ID: id}, nil
	}

	g.log.Error("Cannot find machine with identifier: %s", req.Identifier)
	return nil, machine.ErrMachineNotFound
}
