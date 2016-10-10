package azure

import (
	"errors"
	"fmt"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/provider"

	"github.com/Azure/azure-sdk-for-go/management"
	vm "github.com/Azure/azure-sdk-for-go/management/virtualmachine"
)

type Meta struct {
	AlwaysOn        bool   `bson:"alwaysOn"`
	InstanceID      string `json:"instanceId" bson:"instanceId"`
	HostedServiceID string `json:"hostedServiceId" bson:"hostedServiceId"`
	InstanceType    string `json:"instance_type" bson:"instance_type"`
	Location        string `json:"location" bson:"location"`
	StorageSize     int    `json:"storage_size" bson:"storage_size"`
}

func (mt *Meta) Valid() error {
	if mt.InstanceID == "" {
		return errors.New("invalid empty instance ID")
	}

	if mt.HostedServiceID == "" {
		return errors.New("invalid hosted service ID")
	}

	return nil
}

// Machine represents a single MongodDB document from the jMachines
// collection.
type Machine struct {
	*provider.BaseMachine

	Meta *Meta `bson:"-"`
	Cred *Cred `bson:"-"`

	AzureClient   management.Client        `bson:"-"`
	AzureVMClient *vm.VirtualMachineClient `bson:"-"`
}

// isNotFound tests whether err is a resource not found Azure's error.
func isNotFound(err error) bool {
	// No idea why they return everything by a value - checking
	// for both in case this would get fixed.
	e, ok := err.(*management.AzureError)
	if !ok {
		ee, ok := err.(management.AzureError)
		if ok {
			e = &ee
		}
	}

	return e != nil && e.Code == "ResourceNotFound"
}

func (m *Machine) Status() (machinestate.State, error) {
	resp, err := m.AzureVMClient.GetDeployment(m.Meta.HostedServiceID, m.Meta.InstanceID)
	if isNotFound(err) {
		return machinestate.NotInitialized, nil
	}
	if err != nil {
		return machinestate.Unknown, err
	}

	switch resp.Status {
	case vm.DeploymentStatusRunning:
		return machinestate.Running, nil
	case vm.DeploymentStatusRunningTransitioning,
		vm.DeploymentStatusDeploying,
		vm.DeploymentStatusStarting:
		return machinestate.Starting, nil
	case vm.DeploymentStatusSuspended:
		return machinestate.Stopped, nil
	case vm.DeploymentStatusSuspending,
		vm.DeploymentStatusSuspendedTransitioning:
		return machinestate.Stopping, nil
	case vm.DeploymentStatusDeleting:
		return machinestate.Terminated, nil
	default:
		return machinestate.Unknown, fmt.Errorf("unable to determine vm status: %q", resp.Status)
	}
}
