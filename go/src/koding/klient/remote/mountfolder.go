package remote

import (
	"errors"
	"fmt"
	"os"
	"path"
	"path/filepath"

	"github.com/koding/kite"
	"github.com/koding/logging"

	"koding/fuseklient"
	"koding/klient/remote/machine"
	"koding/klient/remote/mount"
	"koding/klient/remote/req"
)

var (
	ErrExistingMount = errors.New("There's already a mount on that folder.")
)

// MountFolderHandler implements klient's remote.mountFolder method. Mounting
// the given remote folder onto the given local folder.
func (r *Remote) MountFolderHandler(kreq *kite.Request) (interface{}, error) {
	log := logging.NewLogger("remote").New("remote.mountFolder")

	if kreq.Args == nil {
		return nil, errors.New("Required arguments were not passed.")
	}

	var params req.MountFolder
	if err := kreq.Args.One().Unmarshal(&params); err != nil {
		err = fmt.Errorf(
			"remote.mountFolder: Error '%s' while unmarshalling request '%s'\n",
			err, kreq.Args.One(),
		)
		log.Error(err.Error())

		return nil, err
	}

	switch {
	case params.Name == "":
		return nil, errors.New("Missing required argument `name`.")
	case params.LocalPath == "":
		return nil, errors.New("Missing required argument `localPath`.")
	}

	if params.Debug {
		log.SetLevel(logging.DEBUG)
	}

	log = log.New(
		"mountName", params.Name,
		"localPath", params.LocalPath,
	)

	if err := checkIfUserHasFolderPerms(params.LocalPath); err != nil {
		return nil, err
	}

	remoteMachine, err := r.GetValidMachine(params.Name)
	if err != nil {
		log.Error("Error getting valid machine. err:%s", err)
		return nil, err
	}

	if params.RemotePath == "" {
		home, err := remoteMachine.HomeWithDefault()
		if err != nil {
			return nil, err
		}
		params.RemotePath = home
	}

	if !filepath.IsAbs(params.RemotePath) {
		home, err := remoteMachine.HomeWithDefault()
		if err != nil {
			return nil, err
		}
		params.RemotePath = path.Join(home, params.RemotePath)
	}

	if remoteMachine.IsMountingLocked() {
		log.Warning("Mount was attempted but the machine is mount locked")
		return nil, machine.ErrMachineActionIsLocked
	}

	// Lock and defer unlock the machine mount actions
	remoteMachine.LockMounting()
	defer remoteMachine.UnlockMounting()

	if r.mounts.IsDuplicate(remoteMachine.IP, params.RemotePath, params.LocalPath) {
		return nil, ErrExistingMount
	}

	// Construct our mounter
	mounter := &mount.Mounter{
		Log:           log,
		Options:       params,
		Machine:       remoteMachine,
		IP:            remoteMachine.IP,
		KiteTracker:   remoteMachine.KiteTracker,
		Intervaler:    remoteMachine.Intervaler,
		Transport:     remoteMachine,
		PathUnmounter: fuseklient.Unmount,
		MountAdder:    r,
		EventSub:      r.eventSub,
	}

	if _, err := mounter.Mount(); err != nil {
		return nil, err
	}

	remoteMachine.SetStatus(machine.MachineStatusUnknown, "")

	return nil, nil
}

// checkIfUserHasFolderPerms checks if user can at least open the directory
// and returns error if it can't.
func checkIfUserHasFolderPerms(folderPath string) error {
	_, err := os.Open(folderPath)
	return err
}

// getSizeOfLocalFolder asks remote machine for size of specified remote folder
// and returns it in bytes.
func getSizeOfLocalPath(localPath string) (int64, error) {
	var size int64
	err := filepath.Walk(localPath, func(_ string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			size += info.Size()
		}
		return err
	})

	return size, err
}
