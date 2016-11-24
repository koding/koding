package marathon

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"golang.org/x/net/context"
)

// Machine represents a single container within a Marathon app.
type Machine struct {
	*provider.BaseMachine
}

var (
	_ provider.Machine = (*Machine)(nil) // public API
	_ stack.Machiner   = (*Machine)(nil) // internal API
)

func newMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	m := &Machine{BaseMachine: bm}

	return m, nil
}

// Starts starts the app, that is all containers.
//
// It does not support starting a single container within an app,
// so stopping whichever container from the app stops the whole app.
func (m *Machine) Start(ctx context.Context) (interface{}, error) {
	return nil, nil
}

// Stop stops the app, that is all containers.
//
// It does not support stopping a single container within an app,
// so stopping whichever container from the app stops the whole app.
func (m *Machine) Stop(ctx context.Context) (interface{}, error) {
	return nil, nil
}

// Info gives state of the app.
func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	return machinestate.States[m.Status.State], nil, nil
}

// Credential gives a Marathon credential that is attached
// to the m Machine.
func (m *Machine) Credential() *Credential {
	return m.BaseMachine.Credential.(*Credential)
}
