package repair

import (
	"errors"
	"io"
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"os"

	"github.com/koding/logging"
)

// MountEmptyRepair looks at the given mount directory and checks if
// it is empty. If so, we remount.
type MountEmptyRepair struct {
	Log logging.Logger

	Stdout *util.Fprint

	MountName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteMountInfo(string) (req.MountInfoResponse, error)
		RemoteRemount(string) error
	}
}

func (r *MountEmptyRepair) String() string {
	return "MountEmptyRepair"
}

func (r *MountEmptyRepair) getMountPath() (string, error) {
	// Get the mount dir.
	info, err := r.Klient.RemoteMountInfo(r.MountName)
	if err != nil {
		return "", err
	}

	return info.LocalPath, nil
}

func (r *MountEmptyRepair) isDirEmpty(p string) (bool, error) {
	f, err := os.Open(p)
	if err != nil {
		return false, err
	}
	defer f.Close()

	_, err = f.Readdirnames(1)
	if err == io.EOF {
		return true, nil
	}

	return false, err
}

// Status stats the mount directory that klient returns, and if it errors with
// Permission denied, return an error.
func (r *MountEmptyRepair) Status() error {
	path, err := r.getMountPath()

	// If we can't even get the mount dir from klient, return the error
	// so that repair can fail with the same issue.
	//
	// TODO: Fix this behavior by adding bool to Status(), so that errors mean
	// bad things. ~LO
	if err != nil {
		r.Log.Warning("Encountered ignored error. err:%s", err)
		return nil
	}

	if path == "" {
		// TODO: Return this once status is able to separate between ok and error.
		err := errors.New("Mount path was returned empty")
		r.Log.Warning("Encountered ignored error. err:%s", err)
		return nil
	}

	// If the dir is empty, we want to remount.. according to the requirements
	// of this repairer.
	empty, err := r.isDirEmpty(path)
	// TODO: Return this once status is able to separate between ok and error.
	if err != nil {
		r.Log.Warning("Encountered ignored error. err:%s", err)
		return nil
	}

	if empty {
		return errors.New("Empty directory, requires remount")
	}

	return nil
}

// Repair simply remounts the given directory, and then checks the status one more
// time before exiting.
func (r *MountEmptyRepair) Repair() error {
	r.Stdout.Printlnf("Mount dir was found to be empty. Remounting..")

	if err := r.Klient.RemoteRemount(r.MountName); err != nil {
		return err
	}

	// If the mount is legitimately empty, we have a hard time knowing
	// based on this simple test. Regardless, better to not assume success.
	if err := r.Status(); err != nil {
		r.Stdout.Printlnf("Unable to repair empty mount.")
		return err
	}

	return nil
}
