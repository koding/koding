package vagrant

import (
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

func (m *Machine) Build(ctx context.Context) error {
	err := m.start(machinestate.NotInitialized, machinestate.Terminating, machinestate.Terminated)
	if err != nil {
		return kloud.NewEventerError(err)
	}

	return nil
}
