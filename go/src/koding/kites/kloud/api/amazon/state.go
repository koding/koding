package amazon

import (
	"errors"
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/waitstate"
	"strings"

	"github.com/mitchellh/goamz/ec2"
	"golang.org/x/net/context"
)

func (a *Amazon) Start(ctx context.Context) (*protocol.Artifact, error) {
	ev, withPush := eventer.FromContext(ctx)
	if !withPush {
		return nil, errors.New("eventer context is not available")
	}

	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Starting machine",
			Status:     machinestate.Starting,
			Percentage: 10,
		})
	}

	_, err := a.Client.StartInstances(a.Id())
	if err != nil {
		return nil, err
	}

	var instance ec2.Instance
	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		instance, err = a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		Eventer:   ev,
		Action:    "start",
		Start:     25,
		Finish:    60,
	}

	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return &protocol.Artifact{
		InstanceId:   instance.InstanceId,
		IpAddress:    instance.PublicIpAddress,
		InstanceType: a.Builder.InstanceType,
	}, nil
}

func (a *Amazon) Stop(ctx context.Context) error {
	ev, withPush := eventer.FromContext(ctx)
	if !withPush {
		return errors.New("eventer context is not available")
	}

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
		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		Eventer:   ev,
		Action:    "stop",
		Start:     25,
		Finish:    60,
	}

	return ws.Wait()
}

func (a *Amazon) Restart(ctx context.Context) error {
	ev, withPush := eventer.FromContext(ctx)
	if !withPush {
		return errors.New("eventer context is not available")
	}

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
		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		Eventer:   ev,
		Action:    "restart",
		Start:     25,
		Finish:    60,
	}

	return ws.Wait()
}

func (a *Amazon) Destroy(ctx context.Context, start, finish int) error {
	ev, withPush := eventer.FromContext(ctx)
	if !withPush {
		return errors.New("eventer context is not available")
	}

	if a.Id() == "" {
		return errors.New("instance id is empty")
	}

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
		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		Eventer:   ev,
		Action:    "destroy",
		Start:     start,
		Finish:    finish,
	}

	return ws.Wait()
}

func (a *Amazon) Info() (*protocol.InfoArtifact, error) {
	if a.Id() == "" {
		return &protocol.InfoArtifact{
			State: machinestate.NotInitialized,
			Name:  "not-existing-instance",
		}, nil
	}

	instance, err := a.Instance(a.Id())
	if err == ErrNoInstances {
		return &protocol.InfoArtifact{
			State: machinestate.NotInitialized,
			Name:  "not-existing-instance",
		}, nil
	}

	// if it's something else, return it back
	if err != nil {
		return nil, err
	}

	if statusToState(instance.State.Name) == machinestate.Unknown {
		return nil, fmt.Errorf("Unknown amazon status: %+v. This needs to be fixed.", instance.State)
	}

	var instanceName string
	for _, tag := range instance.Tags {
		if tag.Key == "Name" {
			instanceName = tag.Value
		}
	}

	// this shouldn't happen
	if instanceName == "" {
		return nil, fmt.Errorf("instance %s doesn't have a name tag. needs to be fixed!", a.Id())
	}

	return &protocol.InfoArtifact{
		State:        statusToState(instance.State.Name),
		Name:         instanceName,
		InstanceType: instance.InstanceType,
	}, nil

}

// statusToState converts a amazon status to a sensible machinestate.State
// format
func statusToState(status string) machinestate.State {
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
