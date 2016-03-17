package repair

import (
	"errors"
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"os"
	"strings"

	"github.com/koding/logging"
)

// dncSuffix is the suffix of the error mesage returned by the OS when trying to
// open a not-configured device directory.
const dncSuffix = "device not configured"

// DeviceNotConfiguredRepair looks at the given mount directory and checks if
// is a device not configured. If so, remount.
type DeviceNotConfiguredRepair struct {
	Log logging.Logger

	Stdout *util.Fprint

	MountName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteMountInfo(string) (req.MountInfoResponse, error)
		RemoteRemount(string) error
	}
}

func (r *DeviceNotConfiguredRepair) String() string {
	return "DeviceNotConfiguredRepair"
}

func (r *DeviceNotConfiguredRepair) getMountPath() (string, error) {
	// Get the mount dir.
	info, err := r.Klient.RemoteMountInfo(r.MountName)
	if err != nil {
		return "", err
	}

	return info.LocalPath, nil
}

// Status stats the mount directory that klient returns, and if it errors with
// Permission denied, return an error.
func (r *DeviceNotConfiguredRepair) Status() (bool, error) {
	path, err := r.getMountPath()

	// If we can't even get the mount dir from klient, return the error
	// so that repair can fail with the same issue.
	if err != nil {
		return false, err
	}

	f, err := os.Open(path)

	// If open fails with device not configured, we return not okay.
	if err != nil && strings.HasSuffix(err.Error(), dncSuffix) {
		return false, nil
	}

	// If it's another error, log it. In this case there's nothing to do,
	// we don't know what's wrong.
	if err != nil {
		r.Log.Warning("Encountered error not in scope of this repair. err:%s", err)
		return true, nil
	}

	// Not returning an error for mount closing failure. Just logging it.
	if err := f.Close(); err != nil {
		r.Log.Warning(
			"Failed to close MountDir. mountName:%s, dir:%s, err:%s",
			r.MountName, path, err,
		)
	}

	return true, nil
}

// Repair simply remounts the given directory, and then checks the status one more
// time before exiting.
func (r *DeviceNotConfiguredRepair) Repair() error {
	r.Stdout.Printlnf("Mount is no longer valid, remounting...")

	if err := r.Klient.RemoteRemount(r.MountName); err != nil {
		r.Stdout.Printlnf("Unable to remount %s", r.MountName)
		return err
	}

	if ok, err := r.Status(); !ok || err != nil {
		r.Stdout.Printlnf("Unable to repair mount issue.")
		if err == nil {
			err = errors.New("Status returned not-okay after Repair")
		}
		return err
	}

	r.Stdout.Printlnf("Remounted successfully.")

	return nil
}
