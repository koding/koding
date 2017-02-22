package machinegroup

import (
	"errors"
	"fmt"
	"path/filepath"

	"koding/klient/machine"
	"koding/klient/machine/mount"
	msync "koding/klient/machine/mount/sync"
)

// MountRequest defines machine group mount request.
type MountRequest struct {
	// ID is a unique identifier for the remote machine.
	ID machine.ID `json:"id"`

	// Mount describes the mount to be headed.
	Mount mount.Mount `json:"mount"`
}

// HeadMountRequest defines machine group head mount request.
type HeadMountRequest struct {
	MountRequest
}

// HeadMountResponse defines machine group head mount response.
type HeadMountResponse struct {
	// ExistMountID is not empty when mount to a given remote folder already exists.
	ExistMountID mount.ID `json:"existMountID,omitempty"`

	// AbsRemotePath stores absolute representation of remote path.
	AbsRemotePath string `json:"absRemotePath"`

	// AllCount stores the number of all files handled by mount.
	AllCount int `json:"allCount"`

	// AllDiskSize stores the size of all files handled by mount.
	AllDiskSize int64 `json:"allDiskSize"`
}

// HeadMount retrieves information about existing mount or prepares remote
// machine for mounting. It can tell in advance if remote directory exists and
// if it is possible to mount it. This function does not create any mount data.
func (g *Group) HeadMount(req *HeadMountRequest) (*HeadMountResponse, error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	// Check if local path is not already mounted.
	switch mountID, err := g.mount.Path(req.Mount.Path); err {
	case nil:
		return nil, fmt.Errorf("path %q is already used by mount: %s", req.Mount.Path, mountID)
	case mount.ErrMountNotFound: // valid.
	default:
		return nil, err
	}

	c, err := g.client.Client(req.ID)
	if err != nil {
		return nil, err
	}

	absRemotePath, count, diskSize, err := c.MountHeadIndex(req.Mount.RemotePath)
	if err != nil {
		return nil, err
	}

	res := &HeadMountResponse{
		ExistMountID:  "",
		AbsRemotePath: absRemotePath,
		AllCount:      count,
		AllDiskSize:   diskSize,
	}

	// Check if remote folder of provided machine is already mounted.
	mountIDs, err := g.mount.RemotePath(absRemotePath)
	if err != nil {
		if err != mount.ErrMountNotFound {
			g.log.Warning("Cannot obtain list of mounts to %s remote directory: %s", absRemotePath, err)
		}
		return res, nil
	}

	for _, mountID := range mountIDs {
		id, err := g.mount.MachineID(mountID)
		if err != nil {
			continue
		}

		if id == req.ID {
			res.ExistMountID = mountID
			g.log.Warning("Remote machine %s mount to %s already exist: %s", id, absRemotePath, mountID)
			break
		}
	}

	return res, nil
}

// AddMountRequest defines machine group add mount request.
type AddMountRequest struct {
	MountRequest
}

// AddMountResponse defines machine group add mount response.
type AddMountResponse struct {
	// MountID is a unique identifier of created mount.
	MountID mount.ID `json:"mountID"`
}

// AddMount fetches remote index, prepares mount cache, and runs mount sync in
// the background. If this function returns nil, one have to call Unmount method
// in order to remove created mount.
func (g *Group) AddMount(req *AddMountRequest) (res *AddMountResponse, err error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	// Immediately add mount to group, this prevents subtle data races when
	// mounts are added concurrently.
	mountID := mount.MakeID()
	if err = g.mount.Add(req.ID, mountID, req.Mount); err != nil {
		return nil, err
	}
	defer func() {
		if err != nil {
			if e := g.mount.Remove(mountID); e != nil {
				g.log.Error("Cannot clean up mount data for %s", mountID)
			}
		}
	}()

	// Start mount syncer.
	if err = g.sync.Add(mountID, req.Mount, g.dynamicAddr(req.ID), g.dynamicClient(mountID)); err != nil {
		g.log.Error("Synchronization of %s mount failed: %s", mountID, err)
		return nil, err
	}

	g.log.Info("Successfully created mount %s for %s", mountID, req.Mount)

	return &AddMountResponse{
		MountID: mountID,
	}, nil
}

// ListMountRequest defines machine group mount list request.
type ListMountRequest struct {
	// ID is an optional identifier for the remote machine. If set, only
	// mounts related to this machine will be returned.
	ID machine.ID `json:"id,omitempty"`

	// MountID is an optional identifier of a mount which is meant to be listed.
	MountID mount.ID `json:"mountID,omitempty"`
}

// ListMountResponse defines machine group mount list response.
type ListMountResponse struct {
	// Mounts is a map that contains machine aliases as keys and created mount
	// infos which store the current synchronization status of mount.
	Mounts map[string][]msync.Info `json:"mounts"`
}

// ListMount checks the status of mounts and returns their infos. This function
// guarantees that if returned error is nil, response Mounts field is always
// non-nil. It doesn't fail if provided filters contain incorrect values.
func (g *Group) ListMount(req *ListMountRequest) (*ListMountResponse, error) {
	mms, err := g.getMounts(req)
	if err != nil {
		return nil, err
	}

	res := &ListMountResponse{
		Mounts: make(map[string][]msync.Info),
	}

	// Get machine aliases.
	var id2alias = make(map[machine.ID]string)
	for _, mm := range mms {
		if _, ok := id2alias[mm.id]; ok {
			continue
		}

		// Create does not generate new alias if it already exists.
		alias, err := g.alias.Create(mm.id)
		if err != nil {
			// Instead of failing here, use machine ID directly.
			id2alias[mm.id] = string(mm.id)
		} else {
			id2alias[mm.id] = alias
		}
	}

	// Get mount infos.
	for mountID, mm := range mms {
		info, err := g.sync.Info(mountID)
		alias := id2alias[mm.id]
		if err != nil {
			// Add mount to the list but log not synchronized mount.
			res.Mounts[alias] = append(res.Mounts[alias], msync.Info{
				ID:    mountID,
				Mount: mm.m,
			})
			g.log.Warning("Mount %s for %s is not synchronized: %s", mountID, mm.m, err)
			continue
		}

		res.Mounts[alias] = append(res.Mounts[alias], *info)
	}

	return res, nil
}

// mountsMachine is a helper type that contains mount paths and the machine
// which serves its remote path.
type mountsMachine struct {
	m  mount.Mount
	id machine.ID
}

// getRequestedMounts uses filters defined in list mount request to obtain
// list of requested mounts.
func (g *Group) getMounts(req *ListMountRequest) (map[mount.ID]mountsMachine, error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	// Get list of requested mounts with machine ID filter.
	var mms = make(map[mount.ID]mountsMachine)
	if req.ID != "" {
		mounts, err := g.mount.All(req.ID)
		if err != nil {
			return mms, nil
		}

		for mountID, m := range mounts {
			mms[mountID] = mountsMachine{m: m, id: req.ID}
		}
	}

	// Get requested mount with mount ID filter.
	if req.MountID != "" {
		mms = map[mount.ID]mountsMachine{} // Clear map.

		id, err := g.mount.MachineID(req.MountID)
		if err != nil || (req.ID != "" && id != req.ID) {
			return mms, nil
		}

		mounts, err := g.mount.All(id)
		if err != nil {
			return mms, nil
		}

		mms[req.MountID] = mountsMachine{m: mounts[req.MountID], id: id}
	}

	// Get all mounts when filters are not set.
	if req.ID == "" && req.MountID == "" {
		for _, id := range g.mount.Registered() {
			mounts, err := g.mount.All(id)
			if err != nil {
				continue
			}

			for mountID, m := range mounts {
				mms[mountID] = mountsMachine{m: m, id: id}
			}
		}
	}

	return mms, nil
}

// UmountRequest defines machine group umount request.
type UmountRequest struct {
	// Identifier is a string that identifiers requested mount. It can be either
	// mount ID or local path which is going to be unmounted.
	Identifier string `json:"identifier"`
}

// UmountResponse defines machine group umount response.
type UmountResponse struct {
	// MountID is a unique identifier of removed mount.
	MountID mount.ID `json:"mountID"`

	// Mount defines the mount which was removed.
	Mount mount.Mount `json:"mount"`
}

// Umount removes existing mount. It cleans both bolt and mount cache.
func (g *Group) Umount(req *UmountRequest) (res *UmountResponse, err error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	// Get mount ID from identifier.
	mountID, err := mount.IDFromString(req.Identifier)
	if err != nil {
		absPath, e := filepath.Abs(req.Identifier)
		if mountID, err = g.mount.Path(absPath); e != nil || err != nil {
			g.log.Error("Cannot found mount with identifier: %s", req.Identifier)
			return nil, fmt.Errorf("unknown mount: %q", req.Identifier)
		}
	}

	// Stop mount synchronization routine.
	if err := g.sync.Drop(mountID); err != nil {
		g.log.Error("Cannot remove synced mount %s: %s", mountID, err)
		return nil, err
	}

	// Get mount machine.
	id, err := g.mount.MachineID(mountID)
	if err != nil {
		g.log.Error("Could not find machine ID for mount %s: %s", mountID, err)
	}

	var m mount.Mount
	// Get mount object. Ignore errors since mount is only for logging purposes.
	if mounts, err := g.mount.All(id); err == nil {
		m = mounts[mountID]
	}

	// Remove mount from cache. If this operation fails, sync process does not
	// to be restarted.
	if err := g.mount.Remove(mountID); err != nil {
		g.log.Error("Cannot clear mount cache for %s: %s", mountID, err)
	}

	g.log.Info("Successfully removed mount %s for %s", mountID, m)

	return &UmountResponse{
		MountID: mountID,
		Mount:   m,
	}, nil
}
