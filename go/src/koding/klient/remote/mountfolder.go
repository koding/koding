package remote

import (
	"errors"
	"fmt"
	"os"
	"path"
	"regexp"
	"strconv"

	"github.com/koding/kite"

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
)

// MountFolderHandler implements klient's remote.mountFolder method. Mounting
// the given remote folder onto the given local folder.
func (r *Remote) MountFolderHandler(kreq *kite.Request) (interface{}, error) {
	log := r.log.New("remote.mountFolder")

	if kreq.Args == nil {
		return nil, errors.New("Required arguments were not passed.")
	}

	var params req.MountFolder
	if err := kreq.Args.One().Unmarshal(&params); err != nil {
		err = fmt.Errorf(
			"remote.mountFolder: Error '%s' while unmarshalling request '%s'\n",
			err, kreq.Args.One(),
		)
		r.log.Error(err.Error())

		return nil, err
	}

	switch {
	case params.Name == "":
		return nil, errors.New("Missing required argument `name`.")
	case params.LocalPath == "":
		return nil, errors.New("Missing required argument `localPath`.")
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
		// TODO: Deprecate in favor of a more robust way to identify the home dir.
		// This assumes that the username klient is running under has a home
		// at /home/username. Not true for root, if the user isn't the same user
		// as klient is running under, and not true if the homedir isn't /home.
		params.RemotePath = path.Join("/home", remoteMachine.Username)
	}

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
	}

	if _, err := mounter.Mount(); err != nil {
		return nil, err
	}

	// Check the remote size, so we can print a warning to the user if needed.
	if !params.NoPrefetchMeta || !params.PrefetchAll {
		res, err := checkSizeOfRemoteFolder(remoteMachine, params.RemotePath)

		// If there's no error, clear the machine status.
		if err == nil {
			remoteMachine.SetStatus(machine.MachineStatusUnknown, "")
		}

		return res, err
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

// getSizeOfRemoteFolder asks remote machine for size of specified remote folder
// and returns it in bytes.
func getSizeOfRemoteFolder(m *machine.Machine, remotePath string) (int, error) {
	var (
		kreq = struct{ Command string }{"du -sb " + remotePath}
		kres struct {
			Stdout     string `json:"stdout"`
			Stderr     string `json:"stderr"`
			ExitStatus int    `json:"exitStatus"`
		}
	)
	raw, err := m.Tell("exec", kreq)
	if err != nil {
		return 0, err
	}

	if err := raw.Unmarshal(&kres); err != nil {
		return 0, err
	}

	return strconv.Atoi(digitRegex.FindString(kres.Stdout))
}

// checkSizeOfRemoteFolder asks remote machine for size of specified remote folder
// and returns warning if size if greater than 100MB.
//
// Note we return a warning since you can technically mount any size you want,
// however the performance will degrade.
func checkSizeOfRemoteFolder(remoteMachine *machine.Machine, remotePath string) (interface{}, error) {
	sizeInB, err := getSizeOfRemoteFolder(remoteMachine, remotePath)
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
