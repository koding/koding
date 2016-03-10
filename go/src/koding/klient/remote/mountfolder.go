package remote

import (
	"errors"
	"fmt"
	"os"
	"path"
	"regexp"
	"strconv"
	"time"

	"github.com/koding/kite"

	"koding/fuseklient"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/mount"
	"koding/klient/remote/req"
)

const (
	// 1024MB
	recommendedRemoteFolderSize = 1024

	// fuseTellTimout is the timeout that all kite method calls over the network
	// will take to timeout. This should be large enough as to allow large files to
	// be send over the kite callback protocol, but also small enough to allow the
	// network error to be presented to the user in the event of network disruptions.
	//
	// If left too large, the Kernel (in OSX, for example) will fail fs ops by printing
	// "Socket is not connected" to the user. So if that message is seen, this value
	// likely needs to be lowered.
	fuseTellTimeout = 55 * time.Second

	// dialingFailedErrType is the kite.Error.Type used for errors encountered when
	// dialing the remote.
	dialingFailedErrType = "dialing failed"

	// mountNotFound is the kite.Error.Type used for errors encountered when
	// the mount name given cannot be found.
	mountNotFoundErrType = "mount not found"
)

var (
	digitRegex       = regexp.MustCompile(`\d+`)
	ErrExistingMount = errors.New("There's already a mount on that folder.")
)

// MountFolderHandler implements klient's remote.mountFolder method. Mounting
// the given remote folder onto the given local folder.
func (r *Remote) MountFolderHandler(kreq *kite.Request) (interface{}, error) {
	var params req.MountFolder

	if kreq.Args == nil {
		return nil, errors.New("Required arguments were not passed.")
	}

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

	log := r.log.New(
		"mountName", params.Name,
		"localPath", params.LocalPath,
	)

	if err := checkIfUserHasFolderPerms(params.LocalPath); err != nil {
		return nil, err
	}

	remoteMachines, err := r.GetCacheOrMachines()
	if err != nil {
		return nil, err
	}

	remoteMachine, err := remoteMachines.GetByName(params.Name)
	if err != nil {
		return nil, err
	}

	if params.RemotePath == "" {
		params.RemotePath = path.Join("/home", remoteMachine.Client.Username)
	}

	if r.mounts.IsDuplicate(remoteMachine.IP, params.RemotePath, params.LocalPath) {
		return nil, ErrExistingMount
	}

	// Construct our mounter
	mounter := &mount.Mounter{
		Log:           log,
		Options:       params,
		IP:            remoteMachine.IP,
		KitePinger:    remoteMachine.KitePinger,
		Intervaler:    remoteMachine.Intervaler,
		Client:        remoteMachine.Client,
		Dialer:        remoteMachine.Client,
		Teller:        remoteMachine.Client,
		PathUnmounter: fuseklient.Unmount,
		MountAdder:    r,
	}

	if _, err = mounter.Mount(); err != nil {
		return nil, err
	}

	// Check the remote size, so we can print a warning to the user if needed.
	return checkSizeOfRemoteFolder(remoteMachine.Client, params.RemotePath)
}

// checkIfUserHasFolderPerms checks if user can at least open the directory
// and returns error if it can't.
func checkIfUserHasFolderPerms(folderPath string) error {
	_, err := os.Open(folderPath)
	return err
}

// getSizeOfRemoteFolder asks remote machine for size of specified remote folder
// and returns it in bytes.
func getSizeOfRemoteFolder(kiteClient *kite.Client, remotePath string) (int, error) {
	var (
		kreq = struct{ Command string }{"du -sb " + remotePath}
		kres struct {
			Stdout     string `json:"stdout"`
			Stderr     string `json:"stderr"`
			ExitStatus int    `json:"exitStatus"`
		}
	)
	raw, err := kiteClient.Tell("exec", kreq)
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
func checkSizeOfRemoteFolder(kiteClient *kite.Client, remotePath string) (interface{}, error) {
	sizeInB, err := getSizeOfRemoteFolder(kiteClient, remotePath)
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
