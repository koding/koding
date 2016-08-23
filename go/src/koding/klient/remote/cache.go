package remote

import (
	"errors"
	"fmt"
	"path"
	"path/filepath"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/logging"

	"koding/klient/remote/machine"
	"koding/klient/remote/mount"
	"koding/klient/remote/req"
	"koding/klient/remote/rsync"
)

// CacheFolderHandler implements a prefetching / caching mechanism, currently
// implemented
func (r *Remote) CacheFolderHandler(kreq *kite.Request) (interface{}, error) {
	log := logging.NewLogger("remote").New("remote.cacheFolder")

	var params struct {
		req.Cache

		// klient uses vendored version of dnode with path rewrite that's not
		// compatible with other apps, hence we embed common fields into req.Cache
		// and specify dnode.Function by itself
		Progress dnode.Function `json:"progress"`
	}

	if kreq.Args == nil {
		return nil, errors.New("Required arguments were not passed.")
	}

	if err := kreq.Args.One().Unmarshal(&params); err != nil {
		err = fmt.Errorf(
			"remote.cacheFolder: Error '%s' while unmarshalling request '%s'\n",
			err, kreq.Args.One(),
		)
		r.log.Error(err.Error())
		return nil, err
	}

	if params.Debug {
		log.SetLevel(logging.DEBUG)
	}

	switch {
	case params.Name == "":
		return nil, errors.New("Missing required argument `name`.")
	case params.LocalPath == "":
		return nil, errors.New("Missing required argument `localPath`.")
	case params.Username == "":
		return nil, errors.New("Missing required argument `username`.")
	case params.SSHAuthSock == "":
		return nil, errors.New("Missing required argument `sshAuthSock`.")
	}

	log = log.New(
		"mountName", params.Name,
		"localPath", params.LocalPath,
	)

	remoteMachine, err := r.GetDialedMachine(params.Name)
	if err != nil {
		log.Error("Error getting dialed, valid machine. err:%s", err)
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

	if !params.LocalToRemote {
		exists, err := remoteMachine.DoesRemotePathExist(params.RemotePath)
		if err != nil {
			return nil, err
		}

		if !exists {
			return nil, mount.ErrRemotePathDoesNotExist
		}
	}

	var remoteSize int64
	if params.LocalToRemote {
		remoteSize, err = getSizeOfLocalPath(params.LocalPath)
		if err != nil {
			return nil, err
		}
	} else {
		remoteSize, err = remoteMachine.GetFolderSize(params.RemotePath)
		if err != nil {
			return nil, err
		} else {
			log.Debug("Remote path %q is size: %d", params.RemotePath, remoteSize)
		}
	}

	// If there is an actively running intervaler, run the requested cache
	// *between* intervals. Locking to prevent any conflicts between the cache
	// implementation.
	runBetweenIntervals := remoteMachine.Intervaler != nil && params.Interval == 0

	// If there is an interval already running, we may need to stop or pause it.
	replaceIntervaler := remoteMachine.Intervaler != nil && params.Interval != 0

	if replaceIntervaler {
		log.Info("Unsubscribing from existing Sync Intervaler to replace it.")
		remoteMachine.Intervaler.Stop()
	}

	rs := rsync.NewClient(log)
	syncOpts := rsync.SyncIntervalOpts{
		SyncOpts: rsync.SyncOpts{
			Host:              remoteMachine.IP,
			Username:          params.Username,
			RemoteDir:         params.RemotePath,
			LocalDir:          params.LocalPath,
			SSHAuthSock:       params.SSHAuthSock,
			SSHPrivateKeyPath: params.SSHPrivateKeyPath,
			DirSize:           remoteSize,
			LocalToRemote:     params.LocalToRemote,
			IgnoreFile:        params.IgnoreFile,
			IncludePath:       params.IncludePath,
		},
		Interval: params.Interval,
	}

	if params.OnlyInterval {
		startIntervalerIfNeeded(log, remoteMachine, rs, syncOpts)
		return nil, nil
	}

	log.Info("Caching remote via RSync, with options:%#v", syncOpts)
	progCh := rs.Sync(syncOpts.SyncOpts)

	// If a valid callback is not provided, this method blocks until the data is done
	// transferring.
	if !params.Progress.IsValid() {
		log.Debug(
			"Progress callback is not valid. Running remote.cache in synchronous mode.",
		)

		// If there is an existing Intervaler, lock it for the duration of this
		// synchronous method.
		if runBetweenIntervals {
			remoteMachine.Intervaler.Lock()
			defer remoteMachine.Intervaler.Unlock()
		}

		// For predictable behavior we log any errors, but do not immediately return on
		// them. If we return early, RSync may still be running - by blocking until the
		// channel is closed, we ensure that this method, in blocking form, only returns
		// after RSync is done.
		var err error
		for p := range progCh {
			if p.Error.Message != "" {
				log.Error(
					"Error encountered in blocking remote.cache. progress:%d, err:%s",
					p.Progress, p.Error.Message,
				)
				err = errors.New(p.Error.Message)
			}
		}

		// After the progress chan is done, start our SyncInterval
		startIntervalerIfNeeded(r.log, remoteMachine, rs, syncOpts)

		return nil, err
	}

	go func() {
		log.Debug(
			"Progress callback is valid. Running remote.cache in asynchronous mode.",
		)

		// If there is an existing Intervaler, lock it for the duration of this synchronous
		// method.
		if runBetweenIntervals {
			remoteMachine.Intervaler.Lock()
			defer remoteMachine.Intervaler.Unlock()
		}

		for p := range progCh {
			if p.Error.Message != "" {
				log.Error(
					"Error encountered in nonblocking remote.cache. progress:%d, err:%s",
					p.Progress, p.Error.Message,
				)
			}
			params.Progress.Call(p)
		}

		// After the progress chan is done, start our SyncInterval
		startIntervalerIfNeeded(log, remoteMachine, rs, syncOpts)
	}()

	return nil, nil
}

// startIntervalerIfNeeded starts the given rsync interval, logs any errors, and adds the
// resulting Intervaler to the Mount struct for later Stoppage.
func startIntervalerIfNeeded(log logging.Logger, remoteMachine *machine.Machine, c *rsync.Client, opts rsync.SyncIntervalOpts) {
	log = log.New("startIntervalerIfNeeded")

	if opts.Interval <= 0 {
		// Using debug, because this is not an error - just informative.
		log.Debug(
			"startIntervalerIfNeeded() called with interval:%d. Cannot start Intervaler",
			opts.Interval,
		)
		return
	}

	log.Info("Creating and starting RSync SyncInterval")
	intervaler, err := c.SyncInterval(opts)
	if err != nil {
		log.Error("rsync SyncInterval returned an error:%s", err)
		return
	}

	remoteMachine.Intervaler = intervaler
}
