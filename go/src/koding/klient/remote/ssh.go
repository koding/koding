package remote

import (
	"errors"
	"fmt"

	"github.com/koding/kite"

	"koding/klient/remote/req"
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

	remoteMachines, err := r.GetMachines()
	if err != nil {
		return nil, err
	}

	remoteMachine, err := remoteMachines.GetByName(params.Name)
	if err != nil {
		return nil, err
	}

	if err := remoteMachine.CheckValid(); err != nil {
		log.Error("Machine.CheckValid returned not valid. err:%s", err)
		return nil, err
	}

	kiteClient := remoteMachine.Client
	if err := kiteClient.Dial(); err != nil {
		return nil, err
	}

	var sshReq = struct{ Keys []string }{Keys: []string{string(params.Key)}}
	if _, err = kiteClient.Tell("sshkeys.add", sshReq); err != nil {
		return nil, err
	}

	return nil, nil
}
