package machinegroup

import (
	"errors"
	"fmt"

	"koding/klient/machine"
	"koding/klient/machine/mount"
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

	// Start mount synchronization.
	if err = g.sync.Add(mountID, req.Mount); err != nil {
		g.log.Error("Synchronization of %s mount failed: %s", mountID, err)
		return nil, err
	}

	g.log.Info("Successfully created mount %s for %s", mountID, req.Mount)

	return &AddMountResponse{
		MountID: mountID,
	}, nil
}
