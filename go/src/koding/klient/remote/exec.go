package remote

import (
	"errors"
	"fmt"

	"github.com/koding/kite"

	"koding/klient/remote/req"
)

// ExecHandler runs the given command on the given remote klient.
func (r *Remote) ExecHandler(kreq *kite.Request) (interface{}, error) {
	var params req.Exec

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
	case params.Machine == "":
		return nil, errors.New("Missing required argument `machine`.")
	case params.Command == "":
		return nil, errors.New("Missing required argument `command`.")
	}

	remoteMachines, err := r.GetKites()
	if err != nil {
		return nil, err
	}

	remoteMachine, err := remoteMachines.GetByName(params.Machine)
	if err != nil {
		return nil, err
	}

	kiteClient := remoteMachine.Client
	if err := kiteClient.Dial(); err != nil {
		return nil, err
	}

	// cd into path and then run the command if path is not nil.
	var cmd = params.Command
	if params.Path != "" {
		cmd = fmt.Sprintf("cd %s && %s", params.Path, params.Command)
	}

	var execReq = struct{ Command string }{cmd}

	return kiteClient.Tell("exec", execReq)
}
