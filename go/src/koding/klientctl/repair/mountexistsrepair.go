package repair

import (
	"errors"
	"koding/klient/remote/req"
	"koding/klientctl/util"

	"github.com/koding/logging"
)

// MountExistsRepair checks if the mount exists on the filesystem *and*
// Klient. It expects a working klient, kontrol, and remote.
type MountExistsRepair struct {
	Log logging.Logger

	Stdout *util.Fprint

	MountName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteMountInfo(string) (req.MountInfoResponse, error)
	}

	// Mountcli is responsible for looking at our local system and finding a given
	// mount.
	Mountcli interface {
		FindMountedPathByName(string) (string, error)
	}
}

func (r *MountExistsRepair) String() string {
	return "MountExistsRepair"
}

func (r *MountExistsRepair) Status() error {
	_, err := r.Klient.RemoteMountInfo(r.MountName)
	if err != nil {
		return err
	}

	path, err := r.Mountcli.FindMountedPathByName(r.MountName)
	if err != nil {
		return err
	}

	// If path is empty, we could not find the mount name.
	if path == "" {
		return errors.New("Mount cannot be found on file system")
	}

	return nil
}

func (r *MountExistsRepair) Repair() error {
	return errors.New("Not implemented")
}
