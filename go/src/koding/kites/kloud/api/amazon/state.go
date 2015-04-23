package amazon

import (
	"errors"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/waitstate"
	"strings"

	"github.com/mitchellh/goamz/ec2"
	"golang.org/x/net/context"
)

var (
	ErrInstanceIdEmpty = errors.New("instance id is empty")
)

func (a *Amazon) Start(ctx context.Context) (ec2.Instance, error) {
	if a.Id() == "" {
		return ec2.Instance{}, ErrInstanceIdEmpty
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

	_, err := a.Client.StartInstances(a.Id())
	if err != nil {
		return ec2.Instance{}, err
	}

	var instance ec2.Instance
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

		return StatusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Start:        45,
		Finish:       60,
	}

	if err := ws.Wait(); err != nil {
		return ec2.Instance{}, err
	}

	return instance, nil
}

func (a *Amazon) Stop(ctx context.Context) error {
	if a.Id() == "" {
		return ErrInstanceIdEmpty
	}

	// if we have eventer, use it
	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Stopping machine",
			Status:     machinestate.Stopping,
			Percentage: 10,
		})
	}

	_, err := a.Client.StopInstances(a.Id())
	if err != nil {
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

		return StatusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Stopped,
		Start:        25,
		Finish:       60,
	}
	return ws.Wait()
}

func (a *Amazon) Restart(ctx context.Context) error {
	if a.Id() == "" {
		return ErrInstanceIdEmpty
	}

	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Restarting machine",
			Status:     machinestate.Rebooting,
			Percentage: 10,
		})
	}

	_, err := a.Client.RebootInstances(a.Id())
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

		return StatusToState(instance.State.Name), nil
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
		return ErrInstanceIdEmpty
	}

	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Terminating machine",
			Status:     machinestate.Terminating,
			Percentage: start,
		})
	}

	_, err := a.Client.TerminateInstances([]string{a.Id()})
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

		return StatusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Terminated,
		Start:        start,
		Finish:       finish,
	}
	return ws.Wait()
}

// StatusToState converts a amazon status to a sensible machinestate.State
// format
func StatusToState(status string) machinestate.State {
	status = strings.ToLower(status)

	// Valid values: pending | running | shutting-down | terminated | stopping | stopped

	switch status {
	case "pending":
		return machinestate.Starting
	case "running":
		return machinestate.Running
	case "stopped":
		return machinestate.Stopped
	case "stopping":
		return machinestate.Stopping
	case "shutting-down":
		return machinestate.Terminating
	case "terminated":
		return machinestate.Terminated
	default:
		return machinestate.Unknown
	}
}
