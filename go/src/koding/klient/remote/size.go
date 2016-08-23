package remote

import (
	"errors"
	"fmt"
	"koding/klient/remote/mount"
	"koding/klient/remote/req"
	"path"
	"path/filepath"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

// GetPathSize gets the size of a remote path.
func (r *Remote) GetPathSize(kreq *kite.Request) (interface{}, error) {
	log := logging.NewLogger("remote").New("remote.getPathSize")

	var opts req.GetPathSizeOptions
	if kreq.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if err := kreq.Args.One().Unmarshal(&opts); err != nil {
		err = fmt.Errorf(
			"remote.getPathSize: %s, while unmarshalling request: %q\n",
			err, kreq.Args.One(),
		)
		log.Error(err.Error())
		return nil, err
	}

	if opts.Machine == "" {
		return nil, errors.New("missing required argument: machine")
	}

	if opts.Debug {
		log.SetLevel(logging.DEBUG)
	}

	log = log.New(
		"machineName", opts.Machine,
		"remotePath", opts.RemotePath,
	)

	remoteMachine, err := r.GetDialedMachine(opts.Machine)
	if err != nil {
		log.Error("Error getting dialed, valid machine. err:%s", err)
		return nil, err
	}

	if opts.RemotePath == "" {
		log.Debug("RemotePath option is empty, finding default.")

		home, err := remoteMachine.HomeWithDefault()
		if err != nil {
			log.Error("Failed to get remote home. err:%s", err)
			return nil, err
		}
		opts.RemotePath = home
	}

	if !filepath.IsAbs(opts.RemotePath) {
		log.Debug("RemotePath is not absolute. Joining it to home.")

		home, err := remoteMachine.HomeWithDefault()
		if err != nil {
			log.Error("Failed to get remote home. err:%s", err)
			return nil, err
		}
		opts.RemotePath = path.Join(home, opts.RemotePath)
	}

	exists, err := remoteMachine.DoesRemotePathExist(opts.RemotePath)
	if err != nil {
		log.Error("Unable to determine if remote path exists. err:%s", err)
		return nil, err
	}

	if !exists {
		log.Error("Remote path does not exist. path:%s", opts.RemotePath)
		return nil, mount.ErrRemotePathDoesNotExist
	}

	size, err := remoteMachine.GetFolderSize(opts.RemotePath)
	if err != nil {
		log.Error("Failed to get remote size. path:%s, err:%s", opts.RemotePath, err)
	}

	return size, err
}
