package machinegroup

import (
	"koding/klient/machine"
)

// CreateRequest defines machine group create request.
type CreateRequest struct {
	// Addresses represents machines and their known network addresses.
	Addresses map[machine.ID][]machine.Addr `json:"addresses"`
}

// CreateResponse defines machine group create response.
type CreateResponse struct {
	// Statuses store statuses of stored machines. They may not be present if
	// the status was not known.
	Statuses map[machine.ID]machine.Status `json:"statuses"`

	// Returns human readable strings that can replace machine IDs when using
	// machine group API.
	Aliases map[machine.ID]string `json:"aliases"`
}

// Create updates internal state of machine group. It gets the current
// information about user machines so it can add new ones to group.
func (g *Group) Create(req *CreateRequest) (*CreateResponse, error) {
	res := &CreateResponse{
		Statuses: make(map[machine.ID]machine.Status),
		Aliases:  make(map[machine.ID]string),
	}

	for id, addrs := range req.Addresses {
		// Add addresses.
		for _, a := range addrs {
			if err := g.address.Add(id, a); err != nil {
				g.log.Error("Cannot add %s(%s) for %s: %s", a, a.Net, id, err)
				continue
			}
		}

		// Create dynamic client.
		if err := g.client.Create(id, g.dynamicAddr(id)); err != nil {
			g.log.Error("Cannot create client for %s: %s", id, err)
			continue
		}

		// Create and add alias.
		alias, err := g.alias.Create(id)
		if err != nil {
			g.log.Error("Cannot create alias for %s: %s", id, err)
		}
		res.Aliases[id] = alias

		g.log.Debug("Successfully added %s with alias %s", id, alias)
	}

	// Get machine statuses.
	for id := range req.Addresses {
		stat, err := g.client.Status(id)
		if err != nil {
			g.log.Critical("Status for %s is not available: %s", id, err)
			continue
		}
		res.Statuses[id] = stat
	}

	return res, nil
}

// dynamicAddr creates dynamic address functor for the given machine.
func (g *Group) dynamicAddr(id machine.ID) machine.DynamicAddrFunc {
	return func(network string) (machine.Addr, error) {
		return g.address.Latest(id, network)
	}
}
