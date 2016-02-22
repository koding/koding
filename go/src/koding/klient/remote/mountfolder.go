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

	"golang.org/x/net/context"

	"koding/fuseklient"
	"koding/fuseklient/transport"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/req"
	"koding/klient/remote/rsync"
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

		r.log.Info(err.Error())

		return nil, err
	}

	switch {
	case params.Name == "":
		return nil, errors.New("Missing required argument `name`.")
	case params.LocalPath == "":
		return nil, errors.New("Missing required argument `remotePath`.")
	}

	if err := checkIfUserHasFolderPerms(params.LocalPath); err != nil {
		return nil, err
	}

	remoteMachines, err := r.GetKitesOrCache()
	if err != nil {
		return nil, err
	}

	remoteMachine, err := remoteMachines.GetByName(params.Name)
	if err != nil {
		return nil, err
	}

	kiteClient := remoteMachine.Client

	if params.RemotePath == "" {
		params.RemotePath = path.Join("/home", remoteMachine.Client.Username)
	}

	if r.mounts.IsDuplicate(remoteMachine.IP, params.RemotePath, params.LocalPath) {
		return nil, ErrExistingMount
	}

	if err := kiteClient.Dial(); err != nil {
		r.log.Error("Error dialing remote klient. err:%s", err)
		return nil, &kite.Error{
			Type:    dialingFailedErrType,
			Message: err.Error(),
		}
	}

	var syncOpts rsync.SyncIntervalOpts
	if remoteMachine.intervaler != nil {
		syncOpts = remoteMachine.intervaler.SyncIntervalOpts()
	} else {
		r.log.Warning(
			"remote.mountFolder: Unable to locate Intervaler for the remotePath:%s",
			params.RemotePath,
		)
	}

	mount := &Mount{
		MountFolder:      params,
		IP:               remoteMachine.IP,
		MountName:        remoteMachine.Name,
		kitePinger:       remoteMachine.kitePinger,
		intervaler:       remoteMachine.intervaler,
		SyncIntervalOpts: syncOpts,
	}

	// Create our changes channel, so that fuseMount can be told when we lose and
	// reconnect to klient.
	changeSummaries := make(chan kitepinger.ChangeSummary, 1)
	changes := changeSummaryToBool(changeSummaries)

	//if err := fuseMountFolder(mount, kiteClient, changes); err != nil {
	if err := fuseMountFolder(mount, kiteClient); err != nil {
		return nil, err
	}

	if err := r.addMount(mount); err != nil {
		return nil, err
	}

	go watchClientAndReconnect(
		r.log, remoteMachine, mount, kiteClient,
		changeSummaries, changes,
	)

	return checkSizeOfRemoteFolder(kiteClient, params.RemotePath)
}

// fuseMountFolder uses the fuseklient library to mount the given
// folder. It is used in multiple places, and is mainly an abstraction.
func fuseMountFolder(m *Mount, c *kite.Client) error {
	var (
		t   transport.Transport
		err error
	)

	t, err = transport.NewRemoteTransport(c, fuseTellTimeout, m.RemotePath)
	if err != nil {
		return err
	}

	// user specifies to prefetch all content upfront
	if m.PrefetchAll {
		dt, err := transport.NewDiskTransport(m.CachePath)
		if err != nil {
			return err
		}

		// cast into RemoteTransport for NewRemoteOrCacheTransport
		rt := t.(*transport.RemoteTransport)

		t = transport.NewRemoteOrCacheTransport(rt, dt)
	}

	cf := &fuseklient.Config{
		Path:           m.LocalPath,
		MountName:      m.MountName,
		NoIgnore:       m.NoIgnore,
		NoPrefetchMeta: m.NoPrefetchMeta,
		NoWatch:        m.NoWatch,
	}

	f, err := fuseklient.NewKodingNetworkFS(t, cf)
	if err != nil {
		return err
	}

	m.MountedFS = f
	m.unmounter = f

	fs, err := f.Mount()
	if err != nil {
		return err
	}

	// TODO: what context to use?
	go fs.Join(context.TODO())

	return nil
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
