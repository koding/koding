package remote

import (
	"errors"
	"fmt"
	"koding/klient/remote/req"
	"koding/klient/remote/status"

	"github.com/koding/kite"
)

// StatusHandler implements the Kite Handler for the
func (r *Remote) StatusHandler(kreq *kite.Request) (interface{}, error) {
	if kreq.Args == nil {
		return nil, errors.New("Required arguments were not passed.")
	}

	var params req.Status
	if err := kreq.Args.One().Unmarshal(&params); err != nil {
		err = fmt.Errorf(
			"remote.status: Error '%s' while unmarshalling request '%s'\n",
			err, kreq.Args.One(),
		)
		r.log.Error(err.Error())
		return nil, err
	}

	status := status.NewStatus(r.log, r)
	switch params.Item {
	case req.KontrolStatus:
		return nil, status.KontrolStatus()
	case req.MachineStatus:
		return nil, status.MachineStatus(params.MachineName)
	default:
		return nil, fmt.Errorf("Status item %d:%q not supported", params.Item, params.Item)
	}
}
