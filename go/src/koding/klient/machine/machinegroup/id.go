package machinegroup

import (
	"errors"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup/idset"
	"sort"
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

// IdentifierListRequest defines machine group IdentifierList request.
type IdentifierListRequest struct {
	// Return cached machine IDs.
	IDs bool `json:"ids"`

	// Return cached machine aliases.
	Aliases bool `json:"aliases"`

	// Return cached machine IPs.
	IPs bool `josn:"ips"`
}

// IdentifierListResponse defines machine group IdentifierList response.
type IdentifierListResponse struct {
	Identifiers []string `json:"identifiers"`
}

// IdentifierList returns machine identifiers which can be IDs, aliases or/and IPs.
func (g *Group) IdentifierList(req *IdentifierListRequest) (*IdentifierListResponse, error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	var (
		regAlias   = g.alias.Registered()
		regAddress = g.address.Registered()
		regClient  = g.client.Registered()
		regMount   = g.mount.Registered()
	)

	var identifiers []string
	if req.IDs {
		union := idset.Union(
			idset.Union(regAlias, regAddress),
			idset.Union(regClient, regMount),
		)
		for _, id := range union {
			identifiers = append(identifiers, string(id))
		}
	}

	if req.Aliases {
		for _, id := range regAlias {
			if alias, err := g.alias.Create(id); err == nil {
				identifiers = append(identifiers, alias)
			}
		}
	}

	if req.IPs {
		for _, id := range regAddress {
			if ipAddr, err := g.address.Latest(id, "ip"); err == nil {
				identifiers = append(identifiers, ipAddr.Value)
			}
		}
	}

	sort.Strings(identifiers)
	return &IdentifierListResponse{
		Identifiers: identifiers,
	}, nil
}
