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
		RemoteRemount(string) error
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

func (r *MountExistsRepair) Status() (bool, error) {
	// TODO: How do we handle the actual error object here? If Mountcli returns
	// an error, it means the process failed itself. Which means we don't *really*
	// know if the mount exists or not.
	path, err := r.Mountcli.FindMountedPathByName(r.MountName)
	if err != nil {
		r.Log.Error(
			"Error encountered when trying to find Mountcli MountPath by name. name:%s, err:%s",
			r.MountName, err,
		)
		return false, err
	}

	// If path is empty, we could not find the mount name.
	if path == "" {
		r.Stdout.Printlnf("Unable to find %q on filesystem.", r.MountName)
		return false, nil
	}

	return true, nil
}

func (r *MountExistsRepair) Repair() error {
	r.Stdout.Printlnf(
		"Remounting %q to resolve detected issue..",
		r.MountName,
	)

	if err := r.Klient.RemoteRemount(r.MountName); err != nil {
		r.Log.Error(
			"Error when running remote.remount. mountName:%s, err:%s",
			r.MountName, err,
		)
		r.Stdout.Printlnf("Remounting failed.")
		return err
	}

	// Status will print additional messages to the user.
	ok, err := r.Status()
	if !ok && err == nil {
		err = errors.New("Status returned not-okay after Repair")
	}

	return err
}
