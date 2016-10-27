package azure

import (
	"fmt"

	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"github.com/Azure/azure-sdk-for-go/management"
	vm "github.com/Azure/azure-sdk-for-go/management/virtualmachine"
	"golang.org/x/net/context"
)

// Machine represents a single MongodDB document from the jMachines
// collection.
type Machine struct {
	*provider.BaseMachine // base implementation of a machine

	AzureClient   management.Client        `bson:"-"` // Azure API client
	AzureVMClient *vm.VirtualMachineClient `bson:"-"` // Azure API client
}

var (
	_ provider.Machine = (*Machine)(nil) // public API
	_ stack.Machiner   = (*Machine)(nil) // internal API
)

// Cred gives the Azure credentials.
func (m *Machine) Cred() *Cred {
	return m.BaseMachine.Credential.(*Cred)
}

// Bootstrap gives bootstrapping information.
func (m *Machine) Bootstrap() *Bootstrap {
	return m.BaseMachine.Bootstrap.(*Bootstrap)
}

// Meta gives the machine's metadata.
func (m *Machine) Meta() *Meta {
	return m.BaseMachine.Metadata.(*Meta)
}

// Start starts a machine.
func (m *Machine) Start(ctx context.Context) (interface{}, error) {
	id, err := m.AzureVMClient.StartRole(m.Meta().HostedServiceID, m.Meta().InstanceID, m.Meta().InstanceID)
	if err != nil {
		return nil, err
	}

	return nil, m.AzureClient.WaitForOperation(id, nil)
}

// Stop stops a machine.
func (m *Machine) Stop(ctx context.Context) (interface{}, error) {
	id, err := m.AzureVMClient.ShutdownRole(m.Meta().HostedServiceID, m.Meta().InstanceID, m.Meta().InstanceID, vm.PostShutdownActionStoppedDeallocated)
	if err != nil {
		return nil, err
	}

	return nil, m.AzureClient.WaitForOperation(id, nil)
}

// Info gives machine's state.
func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	resp, err := m.AzureVMClient.GetDeployment(m.Meta().HostedServiceID, m.Meta().InstanceID)
	if isNotFound(err) {
		return machinestate.NotInitialized, nil, nil
	}
	if err != nil {
		return machinestate.Unknown, nil, err
	}

	switch resp.Status {
	case vm.DeploymentStatusRunning:
		return machinestate.Running, nil, nil
	case vm.DeploymentStatusRunningTransitioning,
		vm.DeploymentStatusDeploying,
		vm.DeploymentStatusStarting:
		return machinestate.Starting, nil, nil
	case vm.DeploymentStatusSuspended:
		return machinestate.Stopped, nil, nil
	case vm.DeploymentStatusSuspending,
		vm.DeploymentStatusSuspendedTransitioning:
		return machinestate.Stopping, nil, nil
	case vm.DeploymentStatusDeleting:
		return machinestate.Terminated, nil, nil
	default:
		return machinestate.Unknown, nil, fmt.Errorf("unable to determine vm status: %q", resp.Status)
	}
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
