package remote

import (
	"errors"
	"fmt"
	"koding/fuseklient"
	"koding/klient/remote/mount"
	"koding/klient/remote/req"
	"strings"

	"github.com/koding/kite"
)

func (r *Remote) RemountHandler(kreq *kite.Request) (interface{}, error) {
	log := r.log.New("remote.remount")

	if kreq.Args == nil {
		return nil, errors.New("Required arguments were not passed.")
	}

	var params req.Remount
	if err := kreq.Args.One().Unmarshal(&params); err != nil {
		err = fmt.Errorf(
			"Error '%s' while unmarshalling request '%s'\n",
			err, kreq.Args.One(),
		)
		log.Error("Error unmarshalling. err:%s", err)
		return nil, err
	}

	remoteMachine, err := r.GetValidMachine(params.MountName)
	if err != nil {
		log.Error("Error getting valid machine. err:%s", err)
		return nil, err
	}

	existingMount, ok := r.mounts.FindByName(params.MountName)
	if !ok {
		log.Error("Unable to locate mount by name. name:%s", params.MountName, err)
		return nil, mount.ErrMountNotFound
	}

	// We found the mount, add the mount info to the log context
	log = log.New(
		"mountName", existingMount.MountName,
		"localPath", existingMount.LocalPath,
		"remotePath", existingMount.RemotePath,
		"ip:", existingMount.IP,
	)

	if err := r.UnmountFolder(req.UnmountFolder{Name: params.MountName}); err != nil {
		log.Error("Failed to unmount %q. err:%s", params.MountName, err)

		// TODO: Remove this hack once fuseklient is fixed to not return unmount failures
		// for already unmounted directories.
		//
		// This ignores the error:
		// system-unmount-failed: unmount /foo/bar/baz: invalid argument
		if !strings.HasSuffix(err.Error(), "invalid argument") {
			return nil, err
		} else {
			log.Warning("Ignoring unmount error from fuseklient. err:%s", err)
		}
	}

	// Construct our mounter
	mounter := &mount.Mounter{
		Log:           log,
		Options:       existingMount.MountFolder,
		Machine:       remoteMachine,
		IP:            existingMount.IP,
		KiteTracker:   existingMount.KiteTracker,
		Intervaler:    existingMount.Intervaler,
		Transport:     remoteMachine,
		PathUnmounter: fuseklient.Unmount,
		MountAdder:    r,
		EventSub:      r.eventSub,
	}

	if _, err = mounter.Mount(); err != nil {
		return nil, err
	}

	// If the intervaler isn't nil, start it again - since unmount would have stopped
	// it.
	if existingMount.Intervaler != nil {
		log.Info("Starting intervaler.")
		existingMount.Intervaler.Start()
	}

	return nil, nil
}
