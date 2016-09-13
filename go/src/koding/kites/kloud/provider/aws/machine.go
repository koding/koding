package awsprovider

import (
	"errors"
	"koding/kites/kloud/provider"
)

type Meta struct {
	AlwaysOn     bool   `bson:"alwaysOn"`
	InstanceId   string `structs:"instanceId" bson:"instanceId"`
	InstanceType string `structs:"instance_type" bson:"instance_type"`
	InstanceName string `structs:"instanceName" bson:"instanceName"`
	Region       string `structs:"region" bson:"region"`
	StorageSize  int    `structs:"storage_size" bson:"storage_size"`
	SourceAmi    string `structs:"source_ami" bson:"source_ami"`
	SnapshotId   string `structs:"snapshotId" bson:"-"`
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

	Meta *Meta `bson:"-"`
	Cred *Cred `bson:"-"`
}
