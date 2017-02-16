package remote

import (
	"errors"
	"fmt"
	"koding/klient/remote/req"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

// CurrentUsername is the remote variant of klient's os.currentUsername method,
// requesting the currentUsername from the remote machine.
//
// This is mostly used by klientctl's ssh related methods, as the logic for
// ssh lives within klientctl, and therefor klientctl needs to know what
// username to ssh into, if not provided.
func (r *Remote) CurrentUsername(kreq *kite.Request) (interface{}, error) {
	log := r.log.New("remote.currentUsername")

	var opts req.CurrentUsernameOptions

	if kreq.Args == nil {
		err := errors.New("Required arguments were not passed.")
		log.Error(err.Error())
		return nil, err
	}

	if err := kreq.Args.One().Unmarshal(&opts); err != nil {
		err := fmt.Errorf(
			"remote.sshKeyAdd: Error '%s' while unmarshalling request '%s'\n",
			err, kreq.Args.One(),
		)
		log.Error(err.Error())
		return nil, err
	}

	if opts.Debug {
		log.SetLevel(logging.DEBUG)
	}
	log = log.New("machineName", opts.MachineName)

	if opts.MachineName == "" {
		log.Debug("Missing machineName field.")
		return nil, errors.New("Missing required argument `machineName`.")
	}

	remoteMachine, err := r.GetDialedMachine(opts.MachineName)
	if err != nil {
		log.Error("Error getting dialed, valid machine. err:%s", err)
		return nil, err
	}

	res, err := remoteMachine.Tell("os.currentUsername")
	if err != nil {
		log.Debug("Error from remote machine os.currentUsername method. err:%s", err)
		return nil, err
	}

	var username string
	if err := res.Unmarshal(&username); err != nil {
		log.Debug("Failed to unmarshal username string")
		return nil, err
	}

	return username, nil
}
