package machinegroup

import (
	"errors"
	"fmt"

	"koding/klient/machine"
	"koding/klient/machine/mount"
)

// HeadMountRequest defines machine group head mount request.
type HeadMountRequest struct {
	// ID is a unique identifier for the remote machine.
	ID machine.ID `json:"id"`

	// Mount describes the mount to be headed.
	Mount mount.Mount `json:"mount"`
}

// HeadMountResponse defines machine group head mount response.
type HeadMountResponse struct {
	// ExistMountID is not empty when mount to a given remote folder already exists.
	ExistMountID mount.ID `json:"existMountID"`

	// AbsRemotePath stores absolute representation of remote path.
	AbsRemotePath string `json:"absRemotePath"`

	// AllCount stores the number of all files handled by mount.
	AllCount int `json:"allCount"`

	// AllDiskSize stores the size of all files handled by mount.
	AllDiskSize int64 `json:"allDiskSize"`
}

// HeadMount retrieves information on existing mount or prepares remote machine
// for mounting. It can tell in advance if remote directory exists and if it is
// possible to mount it. This function does not create any mount data.
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
