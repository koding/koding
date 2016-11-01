package amazon

import (
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/waitstate"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"golang.org/x/net/context"
)

func (a *Amazon) Start(ctx context.Context) (*ec2.Instance, error) {
	if a.Id() == "" {
		return nil, ErrInstanceEmptyID
	}

	// if we have eventer, use it
	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Starting machine",
			Status:     machinestate.Starting,
			Percentage: 25,
		})
	}

	a.Log.Debug("amazon start eventer: %t", withPush)

	_, err := a.Client.StartInstance(a.Id())
	if err != nil {
		return nil, err
	}

	var instance *ec2.Instance
	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Starting machine",
				Status:     machinestate.Starting,
				Percentage: currentPercentage,
			})
		}

		instance, err = a.Instance()
		if err != nil {
			return 0, err
		}

		return StatusToState(aws.StringValue(instance.State.Name)), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Start:        45,
		Finish:       60,
	}

	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return instance, nil
}

func (a *Amazon) Stop(ctx context.Context) error {
	if a.Id() == "" {
		return ErrInstanceEmptyID
	}

	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Stopping machine",
			Status:     machinestate.Stopping,
			Percentage: 25,
		})
	}

	a.Log.Debug("amazon stop eventer: %t", withPush)

	var (
		// needs to be declared so we can call it recursively
		tryStop   func() error
		tried     int = 0
		lastError error
	)

	// we try to stop if there is an error in the stop instance call. For
	// example if it's a timeout we shouldn't return and try again.
	tryStop = func() error {
		if tried == 2 {
			return fmt.Errorf("Tried to stop three times without any success. Last error is:'%s'",
				lastError)
		}

		_, err := a.Client.StopInstance(a.Id())
		if err != nil {
			lastError = err
			tried++
			return tryStop()
		}

		return nil
	}

	if err := tryStop(); err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Stopping machine",
				Status:     machinestate.Stopping,
				Percentage: currentPercentage,
			})
		}

		instance, err := a.Instance()
		if err != nil {
			return 0, err
		}

		return StatusToState(aws.StringValue(instance.State.Name)), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Stopped,
		Start:        45,
		Finish:       60,
	}
	return ws.Wait()
}

func (a *Amazon) Restart(ctx context.Context) error {
	if a.Id() == "" {
		return ErrInstanceEmptyID
	}

	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Restarting machine",
			Status:     machinestate.Rebooting,
			Percentage: 10,
		})
	}

	err := a.Client.RebootInstance(a.Id())
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Restarting machine",
				Status:     machinestate.Rebooting,
				Percentage: currentPercentage,
			})
		}
		instance, err := a.Instance()
		if err != nil {
			return 0, err
		}

		return StatusToState(aws.StringValue(instance.State.Name)), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Start:        25,
		Finish:       60,
	}
	return ws.Wait()
}

func (a *Amazon) Destroy(ctx context.Context, start, finish int) error {
	if a.Id() == "" {
		return ErrInstanceEmptyID
	}

	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Terminating machine",
			Status:     machinestate.Terminating,
			Percentage: start,
		})
	}

	_, err := a.Client.TerminateInstance(a.Id())
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Terminating machine",
				Status:     machinestate.Terminating,
				Percentage: currentPercentage,
			})
		}

		instance, err := a.Instance()
		if err != nil {
			return 0, err
		}

		return StatusToState(aws.StringValue(instance.State.Name)), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Terminated,
		Start:        start,
		Finish:       finish,
	}
	return ws.Wait()
}
