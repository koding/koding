package google

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"golang.org/x/net/context"
)

// Machine represents a single MongodDB document from the jMachines
// collection.
type Machine struct {
	*provider.BaseMachine
}

var (
	_ provider.Machine = (*Machine)(nil) // public API
	_ stack.Machiner   = (*Machine)(nil) // internal API
)

func (m *Machine) Start(ctx context.Context) (interface{}, error) {
	return nil, nil
}

func (m *Machine) Stop(ctx context.Context) (interface{}, error) {
	return nil, nil
}

func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	return machinestate.Terminated, nil, nil
}

func (m *Machine) Cred() *Cred {
	return m.BaseMachine.Credential.(*Cred)
}

func (m *Machine) Bootstrap() *Bootstrap {
	return m.BaseMachine.Bootstrap.(*Bootstrap)
}
