package amazon

import (
	"time"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/waitstate"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"golang.org/x/net/context"
)

func (a *Amazon) Build(buildData *ec2.RunInstancesInput) (string, error) {
	instance, err := a.Client.RunInstances(buildData)
	if err != nil {
		return "", err
	}
	return aws.StringValue(instance.InstanceId), nil
}

func (a *Amazon) CheckBuild(ctx context.Context, instanceId string, start, finish int) (*ec2.Instance, error) {
	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Building machine",
			Status:     machinestate.Building,
			Percentage: start,
		})
	}

	var instance *ec2.Instance
	var err error
	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Building machine",
				Status:     machinestate.Building,
				Percentage: currentPercentage,
			})
		}

		instance, err = a.Client.InstanceByID(instanceId)
		if err != nil {
			return 0, err
		}

		currentStatus := StatusToState(aws.StringValue(instance.State.Name))

		// happens when there is no volume limit. The instance will be not
		// build and it returns terminated from AWS
		if currentStatus.In(machinestate.Terminated, machinestate.Terminating) {
			return 0, ErrInstanceTerminated
		}

		return currentStatus, nil
	}

	ws := waitstate.WaitState{
		Timeout:      15 * time.Minute,
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Start:        start,
		Finish:       finish,
	}

	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return instance, nil
}

func (a *Amazon) Instance() (*ec2.Instance, error) {
	return a.InstanceByID(a.Builder.InstanceId)
}
