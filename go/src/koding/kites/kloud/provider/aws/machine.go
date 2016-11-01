package aws

import (
	"errors"

	"github.com/aws/aws-sdk-go/aws"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"golang.org/x/net/context"
)

type Meta struct {
	AlwaysOn         bool   `bson:"alwaysOn"`
	InstanceID       string `structs:"instanceId" bson:"instanceId"`
	AvailabilityZone string `structs:"availabilityZone" bson:"availabilityZone"`
	PlacementGroup   string `structs:"placementGroup" bson:"placementGroup"`
	Region           string `structs:"region" bson:"region"`
	StorageSize      int    `structs:"storage_size" bson:"storage_size"`
}

func (mt *Meta) Valid() error {
	if mt.Region == "" {
		return errors.New("invalid empty region")
	}

	return nil
}

// Machine represents a single MongodDB document from the jMachines
// collection.
type Machine struct {
	*provider.BaseMachine

	AWSClient *amazon.Amazon
}

var (
	_ provider.Machine = (*Machine)(nil) // public API
	_ stack.Machiner   = (*Machine)(nil) // internal API
)

func (m *Machine) Start(ctx context.Context) (interface{}, error) {
	_, err := m.AWSClient.Start(ctx)
	return nil, err
}

func (m *Machine) Stop(ctx context.Context) (interface{}, error) {
	return nil, m.AWSClient.Stop(ctx)
}

func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	instance, err := m.AWSClient.Instance()
	if amazon.IsNotFound(err) {
		return machinestate.NotInitialized, nil, nil
	}

	if err != nil {
		return 0, nil, err
	}

	state := amazon.StatusToState(aws.StringValue(instance.State.Name))

	if state == machinestate.Terminating {
		state = machinestate.Terminated
	}

	return state, nil, nil
}

func (m *Machine) Cred() *Cred {
	return m.BaseMachine.Credential.(*Cred)
}

func (m *Machine) Bootstrap() *Bootstrap {
	return m.BaseMachine.Bootstrap.(*Bootstrap)
}
