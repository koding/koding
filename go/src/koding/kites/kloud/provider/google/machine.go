package google

import (
	"errors"
	"net/http"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/waitstate"

	"golang.org/x/net/context"
	compute "google.golang.org/api/compute/v1"
	"google.golang.org/api/googleapi"
)

// Machine represents a single MongodDB document from the jMachines
// collection.
type Machine struct {
	*provider.BaseMachine

	InstancesService *compute.InstancesService
}

var (
	_ provider.Machine = (*Machine)(nil) // public API
	_ stack.Machiner   = (*Machine)(nil) // internal API
)

func newMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	m := &Machine{BaseMachine: bm}
	cred := m.Cred()

	computeService, err := cred.ComputeService()
	if err != nil {
		return nil, err
	}

	m.InstancesService = compute.NewInstancesService(computeService)
	return m, nil
}

// Start starts Google compute instance.
func (m *Machine) Start(ctx context.Context) (interface{}, error) {
	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Starting machine",
			Status:     machinestate.Starting,
			Percentage: 25,
		})
	}

	project, zone, name := m.Location()
	_, err := m.InstancesService.Start(project, zone, name).Do()
	// Ignore http.StatusNotModified status.
	if err != nil && googleapi.IsNotModified(err) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Machine is running",
				Status:     machinestate.Running,
				Percentage: 60,
			})
		}
		return nil, nil
	}
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

// Start stops Google compute instance.
func (m *Machine) Stop(ctx context.Context) (interface{}, error) {
	ev, withPush := eventer.FromContext(ctx)
	if withPush {
		ev.Push(&eventer.Event{
			Message:    "Stopping machine",
			Status:     machinestate.Stopping,
			Percentage: 25,
		})
	}

	project, zone, name := m.Location()
	_, err := m.InstancesService.Stop(project, zone, name).Do()
	// Ignore http.StatusNotModified status.
	if err != nil && googleapi.IsNotModified(err) {
		if withPush {
			ev.Push(&eventer.Event{
				Message:    "Machine stopped",
				Status:     machinestate.Stopped,
				Percentage: 60,
			})
		}
		return nil, nil
	}
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

// Info gets current state of Google compute instance.
func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	project, zone, name := m.Location()
	instance, err := m.InstancesService.Get(project, zone, name).Do()
	if err != nil {
		if isNotFound(err) {
			return machinestate.NotInitialized, nil, nil
		}

		return machinestate.Unknown, nil, err
	}

	state, err := status2state(instance.Status)
	if err != nil {
		return machinestate.Unknown, nil, err
	}

	return state, nil, nil
}

var status2stateMap = map[string]machinestate.State{
	"PROVISIONING": machinestate.Building,
	"STAGING":      machinestate.Starting,
	"RUNNING":      machinestate.Running,
	"STOPPING":     machinestate.Stopping,
	"STOPPED":      machinestate.Stopped,
	"SUSPENDED":    machinestate.Stopped,
	"SUSPENDING":   machinestate.Stopped,
	"TERMINATED":   machinestate.Stopped,
}

func status2state(status string) (machinestate.State, error) {
	state, ok := status2stateMap[status]
	if !ok {
		return machinestate.Unknown, errors.New("unknown instance status: " + status)
	}
	return state, nil
}

func isNotFound(err error) bool {
	if err == nil {
		return false
	}
	ae, ok := err.(*googleapi.Error)
	return ok && ae.Code == http.StatusNotFound
}

// Location gets all information necessary to locate stored instance.
func (m *Machine) Location() (project, zone, name string) {
	metadata := m.BaseMachine.Metadata.(*Meta)
	return m.Cred().Project, metadata.Zone, metadata.Name
}

func (m *Machine) Cred() *Cred {
	return m.BaseMachine.Credential.(*Cred)
}

func (m *Machine) Bootstrap() *Bootstrap {
	return m.BaseMachine.Bootstrap.(*Bootstrap)
}
