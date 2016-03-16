package repair

import (
	"errors"
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"os"

	"github.com/koding/logging"
)

// PermDeniedRepair looks at the given mount directory and checks if
// gives us permission denied. If so, it might be an indication that
// the directory is no longer mounted. Remount.
type PermDeniedRepair struct {
	Log logging.Logger

	Stdout *util.Fprint

	MountName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteMountInfo(string) (req.MountInfoResponse, error)
		RemoteRemount(string) error
	}
}

func (r *PermDeniedRepair) String() string {
	return "PermDeniedRepair"
}

func (r *PermDeniedRepair) getMountPath() (string, error) {
	// Get the mount dir.
	info, err := r.Klient.RemoteMountInfo(r.MountName)
	if err != nil {
		return "", err
	}

	return info.LocalPath, nil
}

// Status stats the mount directory that klient returns, and if it errors with
// Permission denied, return an error.
func (r *PermDeniedRepair) Status() (bool, error) {
	path, err := r.getMountPath()

	// If we can't even get the mount dir from klient, return the error
	// so that repair can fail with the same issue.
	if err != nil {
		return false, err
	}

	// Stat should not fail if it's a perm denied (655) problem, the mount exists.
	// So, we ignore this error.
	fi, err := os.Stat(path)
	if err != nil {
		return false, err
	}

	if fi.Mode() == os.FileMode(0655)|os.ModeDir {
		return false, nil
	}

	return true, nil
}

// Repair simply remounts the given directory, and then checks the status one more
// time before exiting.
func (r *PermDeniedRepair) Repair() error {
	r.Stdout.Printlnf("Mount dir contains the wrong permissions, remounting..")

	if err := r.Klient.RemoteRemount(r.MountName); err != nil {
		r.Stdout.Printlnf("Unable to remount %s", r.MountName)
		return err
	}

	if ok, err := r.Status(); !ok || err != nil {
		r.Stdout.Printlnf("Unable to repair permissions issue.")
		if err == nil {
			err = errors.New("Status returned not-okay after running Repair")
		}
		return err
	}

	r.Stdout.Printlnf("Remounted successfully.")

	return nil
}
