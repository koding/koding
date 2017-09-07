package machinegroup

import (
	"errors"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup/idset"
)

// CreateRequest defines machine group create request.
type CreateRequest struct {
	// Addresses represents machines and their known network addresses.
	Addresses map[machine.ID][]machine.Addr `json:"addresses"`

	// Metadata stores additional information about the machine.
	Metadata map[machine.ID]*machine.Metadata `json:"metadata"`
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
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	res := &CreateResponse{
		Statuses: make(map[machine.ID]machine.Status),
		Aliases:  make(map[machine.ID]string),
	}

	for id, addrs := range req.Addresses {
		// Add addresses.
		for _, a := range addrs {
			if err := g.address.Add(id, a); err != nil {
				g.log.Error("Cannot add %s for %s: %s", a, id, err)
				continue
			}
		}

		// Create dynamic client.
		if err := g.client.Create(id, g.dynamicAddr(id), g.addrSet(id)); err != nil {
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

	for id, meta := range req.Metadata {
		// Add machine metadata.
		if err := g.meta.Add(id, meta); err != nil {
			g.log.Error("Cannot add metadata for %s machine: %s", id, err)
		}
	}

	// Update cache asynchronously.
	go func() {
		if cache, ok := g.address.(machine.Cacher); ok {
			if err := cache.Cache(); err != nil {
				g.log.Warning("Cannot cache machine addresses: %v", err)
			}
		}
		if cache, ok := g.alias.(machine.Cacher); ok {
			if err := cache.Cache(); err != nil {
				g.log.Warning("Cannot cache machine aliases: %v", err)
			}
		}
		if cache, ok := g.meta.(machine.Cacher); ok {
			if err := cache.Cache(); err != nil {
				g.log.Warning("Cannot cache machine metadata: %v", err)
			}
		}

		g.log.Debug("Updating machine cache finished")
	}()

	// Get machine statuses.
	ids := make(machine.IDSlice, 0, len(req.Addresses))
	for id := range req.Addresses {
		ids = append(ids, id)
		stat, err := g.client.Status(id)
		if err != nil {
			g.log.Critical("Status for %s is not available: %s", id, err)
			continue
		}
		res.Statuses[id] = stat
	}

	// Update and clean up stale machines. No need to block here.
	go g.balance(ids)

	return res, nil
}

// balance ensures that stale clients and other resources will be closed and
// removed. Mounted machines are not deleted.
func (g *Group) balance(ids machine.IDSlice) {
	var (
		regAlias   = g.alias.Registered()
		regMeta    = g.meta.Registered()
		regAddress = g.address.Registered()
		regClient  = g.client.Registered()
		regMount   = g.mount.Registered()
	)

	union := idset.Union(idset.Union(regAlias, regAddress), idset.Union(regClient, regMeta))

	// Remove machines that are no longer available. Leave these with mounts
	// untouched.
	for _, id := range idset.Diff(idset.Diff(union, regMount), ids) {
		var errored = false

		// Drop machine alias.
		if err := g.alias.Drop(id); err != nil {
			errored = true
			g.log.Warning("Alias of machine %s cannot be removed: %v", id, err)
		}

		// Drop machine metadata.
		if err := g.meta.Drop(id); err != nil {
			errored = true
			g.log.Warning("Metadata of machine %s cannot be removed: %v", id, err)
		}

		// Drop machine client.
		if err := g.client.Drop(id); err != nil {
			errored = true
			g.log.Warning("Client for machine %s cannot be deleted: %v", id, err)
		}

		// Drop all machine addresses.
		if err := g.address.Drop(id); err != nil {
			errored = true
			g.log.Warning("Addresses of %s machine cannot be removed: %v", id, err)
		}

		if !errored {
			g.log.Info("Machine with ID: %s was removed.", id)
		}
	}

	// Log machines that have stale mounts.
	for _, id := range idset.Diff(regMount, ids) {
		mounts, err := g.mount.All(id)
		if err != nil {
			g.log.Error("Cannot retrieve stale mounts for %s machine: %s", id, err)
			continue
		}

		for mountID, m := range mounts {
			g.log.Info("Stale mount %s (%s) for machine with ID: %s", mountID, m, id)
		}
	}
}
