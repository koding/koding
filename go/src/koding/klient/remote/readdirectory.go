package remote

import (
	"errors"
	"fmt"
	"koding/klient/remote/req"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

//  implements a prefetching / caching mechanism, currently
// implemented
func (r *Remote) ReadDirectoryHandler(kreq *kite.Request) (interface{}, error) {
	log := logging.NewLogger("remote").New("remote.readDirectory")

	var params req.ReadDirectoryOptions
	if kreq.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if err := kreq.Args.One().Unmarshal(&params); err != nil {
		err = fmt.Errorf(
			"remote.readDirectory: Error '%s' while unmarshalling request '%s'\n",
			err, kreq.Args.One(),
		)
		r.log.Error(err.Error())
		return nil, err
	}

	switch {
	case params.Machine == "":
		return nil, errors.New("Missing required argument `machine`.")
	}

	log = log.New(
		"machineName", params.Machine,
		"remotePath", params.Path,
	)

	remoteMachine, err := r.GetDialedMachine(params.Machine)
	if err != nil {
		log.Error("Error getting dialed, valid machine. err:%s", err)
		return nil, err
	}

	if params.Path == "" {
		home, err := remoteMachine.Home()
		if err != nil {
			return nil, err
		}
		params.Path = home
	}

	return remoteMachine.Tell("fs.readDirectory", params)
}
