package stack

import (
	"strings"

	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/machinestate"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

func (k *Kloud) Info(r *kite.Request) (interface{}, error) {
	machine, err := k.GetMachine(r)
	if err != nil {
		return nil, err
	}

	if machine.State() == machinestate.NotInitialized {
		return &InfoResponse{
			State: machinestate.NotInitialized,
			Name:  "not-initialized-instance",
		}, nil
	}

	ctx := request.NewContext(context.Background(), r)
	response, err := machine.HandleInfo(ctx)
	if err != nil {
		return nil, err
	}

	if response.State == machinestate.Unknown {
		response.State = machine.State()
	}

	return response, nil
}

func (k *Kloud) Start(r *kite.Request) (resp interface{}, reqErr error) {
	startFunc := func(ctx context.Context, machine Machiner) error {
		err := machine.HandleStart(ctx)
		if err != nil {
			// special case `NetworkOut` error since client relies on this
			// to show a modal
			if strings.Contains(err.Error(), "NetworkOut") {
				err = NewEventerError(err)
			}

			// special case `plan is expired` error since client relies on this to
			// show a modal
			if strings.Contains(strings.ToLower(err.Error()), "plan is expired") {
				err = NewEventerError(err)
			}
		}

		return err
	}

	return k.coreMethods(r, startFunc)
}

func (k *Kloud) Stop(r *kite.Request) (resp interface{}, reqErr error) {
	stopFunc := func(ctx context.Context, machine Machiner) error {
		return machine.HandleStop(ctx)
	}

	return k.coreMethods(r, stopFunc)
}
