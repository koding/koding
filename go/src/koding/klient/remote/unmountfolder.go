package remote

import (
	"errors"
	"fmt"

	"github.com/koding/kite"

	"koding/klient/remote/req"
)

const (
	// systemUnmountFailed is the Kite Error Type used when either the unmounter
	// fails, or generic (non-instanced) unmount fails.
	systemUnmountFailed = "system-unmount-failed"

	// mountNotFoundNoPath is returned when we were unable to find the given mount
	// name, *and* the localPath is empty.
	mountNotFoundNoPath = "mount-not-found-no-path"
)

// UnmountFolderHandler implements a kite handler for Remote.UnmountFolder
func (r *Remote) UnmountFolderHandler(kreq *kite.Request) (interface{}, error) {
	var params req.UnmountFolder

	if kreq.Args == nil {
		return nil, errors.New("Required argument `name` was not passed.")
	}

	if err := kreq.Args.One().Unmarshal(&params); err != nil {
		err = fmt.Errorf(
			"Error '%s' while unmarshalling request '%s'.\n", err, kreq.Args.One(),
		)

		r.log.Error(err.Error())

		return nil, err
	}

	return nil, r.UnmountFolder(params)
}

// UnmountFolder implements klient's remote.unmountFolder method. Unmounting
// the given local folder.
func (r *Remote) UnmountFolder(params req.UnmountFolder) error {
	if params.Name == "" && params.LocalPath == "" {
		return errors.New("Missing required argument `name` or `localPath`.")
	}

	m, ok := r.mounts.FindByName(params.Name)
	if !ok {
		r.log.Warning(
			"remote.unmountFolder: Unable to find mount instance. name:%s, localPath:%s",
			params.Name, params.LocalPath,
		)

		// If we are unable to find the mount instance. If the localPath is also empty,
		// there's nothing we can do - return an error.
		//
		// We're returning a custom kite-error, so that klientctl can check for this
		// specific error type and return a custom UX for this specific error.
		if params.LocalPath == "" {
			return &kite.Error{
				Type: mountNotFoundNoPath,
				Message: fmt.Sprintf(
					"Unable to locate the mount name %s, and localPath is empty.",
					params.Name,
				)}
		}

		// If we can't find the mount, but a localPath was supplied, unmount that.
		if err := r.unmountPath(params.LocalPath); err != nil {
			// We're using a custom error here, to help KD identify a possibly common
			// error circumstance and report it to the user.
			return newKiteErr(systemUnmountFailed, err)
		}

		// Mount wasn't found, but we succeeded in mounting the localPath. End of func.
		return nil
	}

	if m.Intervaler != nil {
		r.log.Info(
			"remote.unmountFolder: Unsubscribing from Sync Intervaler. Ip:%s, localPath:%s",
			m.IP, m.LocalPath,
		)

		m.Intervaler.Stop()
	} else {
		r.log.Warning(
			"remote.unmountFolder: Unable to locate Sync Intervaler. remotePath:%s, name:%s",
			m.RemotePath, m.MountName,
		)
	}

	if m.KitePinger != nil {
		r.log.Info(
			"remote.unmountFolder: Unsubscribing from kitePinger. Ip:%s, localPath:%s",
			m.IP, m.LocalPath,
		)

		m.KitePinger.Unsubscribe(m.PingerSub)
	} else {
		r.log.Warning(
			"remote.unmountFolder: Unable to locate kitePinger. remotePath:%s, name:%s",
			m.RemotePath, m.MountName,
		)
	}

	if m.Log == nil {
		m.Log = r.log
	}

	// If removeMount encounters an error, we don't want to bail immediately.
	// Rather, we want to still try to unmount the folder.
	removeMountErr := r.RemoveMount(m)
	if removeMountErr != nil {
		r.log.Error(
			"remote.unmountFolder: removeMount failed. name:%s, localPath:%s, err:%s",
			params.Name, params.LocalPath, removeMountErr,
		)
	}

	if err := m.Unmount(); err != nil {
		r.log.Error(
			"remote.unmountFolder: Unmount failed. name:%s, localPath:%s, err:%s",
			params.Name, m.LocalPath, err,
		)

		// Note that we're choosing to return the unmounter error here, rather than
		// a possible error from removeMount.
		//
		// We're using a custom error here, to help KD identify a possibly common
		// error circumstance and report it to the user.
		return newKiteErr(systemUnmountFailed, err)
	}

	return removeMountErr
}

// newKiteErr creates a new kite error from the given type-string and error.
func newKiteErr(t string, err error) *kite.Error {
	return &kite.Error{
		Type:    t,
		Message: err.Error(),
	}
}
