package remote

import (
	"errors"
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/logging"

	"koding/klient/remote/req"
	"koding/klient/sshkeys"
)

// SSHKeyAddHandler adds the specified public SSH key to remote machine via the klient
// on the remote machine.
func (r *Remote) SSHKeyAddHandler(kreq *kite.Request) (interface{}, error) {
	log := r.log.New("remote.sshKeyAdd")

	var params req.SSHKeyAdd

	if kreq.Args == nil {
		return nil, errors.New("Required arguments were not passed.")
	}

	if err := kreq.Args.One().Unmarshal(&params); err != nil {
		err = fmt.Errorf(
			"remote.sshKeyAdd: Error '%s' while unmarshalling request '%s'\n",
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
	case len(params.Key) == 0:
		return nil, errors.New("Missing required argument `key`.")
	}

	log = log.New(
		"mountName", params.Name,
		// Using len to avoid printing the whole key.
		"keyLength", len(params.Key),
	)

	remoteMachine, err := r.GetDialedMachine(params.Name)
	if err != nil {
		log.Error("Error getting dialed, valid machine. err:%s", err)
		return nil, err
	}

	username := params.Username

	// If the username is empty, default it to the current user on the remote side.
	if params.Username == "" {
		log.Debug("Username empty, looking up default.")

		res, err := remoteMachine.Tell("os.currentUsername")
		if err != nil {
			log.Debug("Error from remote machine os.currentUsername method. err:%s", err)
			return nil, err
		}

		if err := res.Unmarshal(&username); err != nil {
			log.Debug("Failed to unmarshal username string")
			return nil, err
		}
	}

	log.Debug("Adding key for username %q", username)
	var sshReq = sshkeys.AddOptions{
		Username: username,
		Keys:     []string{string(params.Key)},
	}
	if _, err := remoteMachine.Tell("sshkeys.add", sshReq); err != nil {
		log.Debug("Error from remote machine sshkeys.add method. err:%s", err)
		return nil, err
	}

	return nil, nil
}
