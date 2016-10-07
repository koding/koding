package softlayer

import (
	"errors"

	// "koding/kites/kloud/api/sl"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack/provider"

	softlayerGo "github.com/maximilien/softlayer-go/client"

	"golang.org/x/net/context"
)

var (
	_ provider.Machine = (*Machine)(nil)
)

// Represents a single Softlayer instance. It is responsible for
// starting/stopping of the remote instance via it's client
// which implements the remote Softlayer API
type Machine struct {
	*provider.BaseMachine

	Client *softlayerGo.SoftLayerClient
}

// Uses credentials provided during stack build to create
// a Softlayer machine representation and it's client
func NewMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	c, ok := bm.Credential.(*Credential)
	if !ok {
		return nil, errors.New("not a valid Soflayer credential")
	}

	m := &Machine{
		BaseMachine: bm,
		Client:      softlayerGo.NewSoftLayerClient(c.Username, c.ApiKey),
	}

	return m, nil
}

// Start the remote Softlayer instance.
func (m *Machine) Start(ctx context.Context) (interface{}, error) {
	// template := m.Client

	// TODO:

	return nil, nil
}

// Stop the remote Softlayer instance.
func (m *Machine) Stop(ctx context.Context) (interface{}, error) {
	// TODO:
	return nil, nil
}

// Returns the state of the remote Softlayer instance
func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	// TODO: actually query state of Softlayer instance

	return machinestate.Running, nil, nil
}

// Returns credential value using the provider defined type.
func (m *Machine) Credential() *Credential {
	return m.BaseMachine.Credential.(*Credential)
}

// Returns bootstrap value using the provider defined type.
func (m *Machine) Bootstrap() *Bootstrap {
	return m.BaseMachine.Bootstrap.(*Bootstrap)
}

// Returns the metadata value using the provider defined type.
func (m *Machine) Metadata() *Metadata {
	return m.BaseMachine.Metadata.(*Metadata)
}
