package remote

import (
	"errors"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"regexp"

	"github.com/koding/kite"
	"github.com/koding/logging"

	"koding/fuseklient"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/machine"
	"koding/klient/remote/mount"
	"koding/klient/remote/req"
)

const (
	// 1024MB
	recommendedRemoteFolderSize = 1024
)

var (
	digitRegex       = regexp.MustCompile(`\d+`)
	ErrExistingMount = errors.New("There's already a mount on that folder.")

	// errGetSizeMissingRemotePath is returned when the getSizeOfRemoteFolder method
	// is missing the remote path argument.
	errGetSizeMissingRemotePath = errors.New("A remote path is required.")

	// errGetSizeMissingMachine is returned when the getSizeOfRemoteFolder method
	// is missing the machine argument.
	errGetSizeMissingMachine = errors.New("A machine instance is required.")
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

// checkSizeOfRemoteFolder asks remote machine for size of specified remote folder
// and returns warning if size if greater than 100MB.
//
// Note we return a warning since you can technically mount any size you want,
// however the performance will degrade.
func checkSizeOfRemoteFolder(remoteMachine *machine.Machine, remotePath string) (interface{}, error) {
	sizeInB, err := remoteMachine.GetFolderSize(remotePath)
	if err != nil {
		return nil, err
	}

	sizeInMB := sizeInB / (1024 * 1000)

	if sizeInMB > recommendedRemoteFolderSize {
		return fmt.Sprintf(
			"Specified remote folder size is '%dMB', recommended is '%dMB' or less.",
			sizeInMB, recommendedRemoteFolderSize,
		), nil
	}

	return nil, nil
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

// changeSummaryToBool is a simple func that converts a ChangeSummary channel to a
// bool channel, based on Success or Failure (success is true, failure is false).
func changeSummaryToBool(s chan kitepinger.ChangeSummary) <-chan bool {
	b := make(chan bool)
	go func() {
		for change := range s {
			switch change.NewStatus {
			case kitepinger.Success:
				b <- true
			case kitepinger.Failure:
				b <- false
			}
		}
		close(b)
	}()
	return b
}
