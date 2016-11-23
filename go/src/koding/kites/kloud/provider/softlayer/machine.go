package softlayer

import (
	"errors"
	"strings"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/waitstate"

	"golang.org/x/net/context"

	softlayerGo "github.com/maximilien/softlayer-go/client"
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
	ev, withPush := eventer.FromContext(ctx)

	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Starting machine",
			Status:     machinestate.Starting,
			Percentage: 25,
		})
	}

	metadata := m.BaseMachine.Metadata.(*Metadata)

	service, err := m.Client.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return nil, err
	}

	_, err = service.PowerOn(metadata.Id)
	if err != nil {
		return nil, err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Starting machine",
				Status:     machinestate.Starting,
				Percentage: currentPercentage,
			})
		}

		state, _, err := m.Info(nil)
		if err != nil {
			return machinestate.Unknown, err
		}

		return state, err
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Start:        45,
		Finish:       60,
	}

	return nil, ws.Wait()
}

// Stop the remote Softlayer instance.
func (m *Machine) Stop(ctx context.Context) (interface{}, error) {
	ev, withPush := eventer.FromContext(ctx)

	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Stopping machine",
			Status:     machinestate.Stopping,
			Percentage: 25,
		})
	}

	metadata := m.BaseMachine.Metadata.(*Metadata)

	service, err := m.Client.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return nil, err
	}

	_, err = service.PowerOffSoft(metadata.Id)
	if err != nil {
		return nil, err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Stopping machine",
				Status:     machinestate.Stopping,
				Percentage: currentPercentage,
			})
		}

		state, _, err := m.Info(nil)
		if err != nil {
			return machinestate.Unknown, err
		}

		return state, err
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Stopped,
		Start:        45,
		Finish:       60,
	}

	return nil, ws.Wait()
}

// Returns the state of the remote Softlayer instance
func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	metadata := m.BaseMachine.Metadata.(*Metadata)

	service, err := m.Client.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return machinestate.Unknown, nil, err
	}

	state, err := service.GetPowerState(metadata.Id)
	if err != nil {
		return machinestate.Unknown, nil, err
	}

	return toMachineState(state.Name), nil, nil
}

func toMachineState(softlayerState string) machinestate.State {
	switch strings.ToLower(softlayerState) {
	case "running":
		return machinestate.Running
	case "halted":
		return machinestate.Stopped
	default:
		return machinestate.Unknown
	}
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
