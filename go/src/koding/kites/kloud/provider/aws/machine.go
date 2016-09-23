package aws

import (
	"errors"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stackplan"

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
	*stackplan.BaseMachine

	AWSClient *amazon.Amazon
}

var _ stackplan.Machine = (*Machine)(nil)

func (m *Machine) Start(context.Context) (interface{}, error) {
}

func (m *Machine) Stop(context.Context) (interface{}, error) {
}

func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
}

func (m *Machine) Cred() *Cred {
	return m.BaseMachine.Credential.(*Cred)
}

func (m *Machine) Bootstrap() *Bootstrap {
	return m.BaseMachine.Bootstrap.(*Bootstrap)
}
