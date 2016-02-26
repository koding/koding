package remote

import (
	"errors"
	"fmt"
	"koding/klient/remote/req"
	"koding/klient/util"

	"github.com/koding/kite"
	kiteprotocol "github.com/koding/kite/protocol"
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
		r.log.Info(err.Error())
		return nil, err
	}

	return r.Status(params)
}

func (r *Remote) Status(params req.Status) (bool, error) {
	switch params.Item {
	case req.KontrolStatus:
		return r.KontrolStatus()
	case req.MachineStatus:
		return r.MachineStatus(params.MachineName)
	default:
		return false, errors.New("Status item implemented")
	}
}

func (r *Remote) KontrolStatus() (bool, error) {
	_, err := r.kitesGetter.GetKodingKites(&kiteprotocol.KontrolQuery{
		Name:     "klient",
		Username: r.localKite.Config.Username,
	})

	if err != nil {
		return false, fmt.Errorf("Unable to get kontrol connection. err:%s", err)
	}

	return true, nil
}

func (r *Remote) MachineStatus(name string) (bool, error) {
	remoteMachines, err := r.GetKitesOrCache()
	if err != nil {
		return false, err
	}

	remoteMachine, err := remoteMachines.GetByName(name)
	if err != nil {
		return false, util.NewKiteError(machineNotFoundErrType, err)
	}

	kiteClient := remoteMachine.Client
	if err := kiteClient.Dial(); err != nil {
		r.log.Error("Error dialing remote klient. err:%s", err)
		return false, util.NewKiteError(dialingFailedErrType, err)
	}

	return true, nil
}
