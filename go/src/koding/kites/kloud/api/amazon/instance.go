package amazon

import (
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/waitstate"
	"time"

	"golang.org/x/net/context"

	"github.com/mitchellh/goamz/ec2"
)

func (a *Amazon) Build(buildData *ec2.RunInstances) (string, error) {
	resp, err := a.Client.RunInstances(buildData)
	if err != nil {
		return "", err
	}

	// we do not check intentionally, because CreateInstance() is designed to
	// create only one instance. If it creates something else we catch it here
	// by panicing
	instance := resp.Instances[0]

	return instance.InstanceId, nil
}

func (a *Amazon) CheckBuild(ctx context.Context, instanceId string, start, finish int) (ec2.Instance, error) {
	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Building machine",
			Status:     machinestate.Building,
			Percentage: start,
		})
	}

	var instance ec2.Instance
	var err error
	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Building machine",
				Status:     machinestate.Building,
				Percentage: currentPercentage,
			})
		}

		instance, err = a.InstanceById(instanceId)
		if err != nil {
			return 0, err
		}

		currentStatus := StatusToState(instance.State.Name)

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
		return ec2.Instance{}, err
	}

	return instance, nil
}

func (a *Amazon) Instance() (ec2.Instance, error) {
	return a.InstanceById(a.Builder.InstanceId)
}

func (a *Amazon) InstanceById(id string) (ec2.Instance, error) {
	resp, err := a.Client.Instances([]string{id}, ec2.NewFilter())
	if err != nil {
		if awsErr, ok := err.(*ec2.Error); ok {
			if awsErr.Code == "InvalidInstanceID.NotFound" {
				return ec2.Instance{}, ErrNoInstances
			}
		}

		return ec2.Instance{}, err
	}

	if len(resp.Reservations) == 0 {
		fmt.Errorf("the instance ID '%s' does not exist", id)
		return ec2.Instance{}, ErrNoInstances
	}

	return resp.Reservations[0].Instances[0], nil
}

func (a *Amazon) InstancesByFilter(filter *ec2.Filter) ([]ec2.Instance, error) {
	if filter == nil {
		filter = ec2.NewFilter()
	}

	resp, err := a.Client.Instances([]string{}, filter)
	if err != nil {
		return nil, err
	}

	if len(resp.Reservations) == 0 {
		return nil, ErrNoInstances
	}

	// we don't care about reservations and every reservation struct returns
	// only on single instance. Just collect them and return a list of
	// instances
	instances := make([]ec2.Instance, len(resp.Reservations))
	for i, r := range resp.Reservations {
		instances[i] = r.Instances[0]
	}

	return instances, nil
}

func (a *Amazon) SecurityGroup(name string) (ec2.SecurityGroup, error) {
	// Somehow only filter works, defining inside SecurityGroup doesn't work
	filter := ec2.NewFilter()
	filter.Add("group-name", name)

	resp, err := a.Client.SecurityGroups([]ec2.SecurityGroup{}, filter)
	if err != nil {
		return ec2.SecurityGroup{}, err
	}

	if len(resp.Groups) == 0 {
		return ec2.SecurityGroup{}, fmt.Errorf("the security group name '%s' does not exist", name)
	}

	return resp.Groups[0].SecurityGroup, nil
}

func (a *Amazon) ListVPCs() (*ec2.VpcsResp, error) {
	return a.Client.DescribeVpcs([]string{}, ec2.NewFilter())
}

func (a *Amazon) ListSubnets() (*ec2.SubnetsResp, error) {
	return a.Client.DescribeSubnets([]string{}, ec2.NewFilter())
}

func (a *Amazon) ListSubnetsFromVPC(vpcId string) (*ec2.SubnetsResp, error) {
	filter := ec2.NewFilter()
	filter.Add("vpc-id", vpcId)

	return a.Client.DescribeSubnets([]string{}, filter)
}
