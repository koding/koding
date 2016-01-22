package vagrant

import (
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

func (m *Machine) Build(ctx context.Context) error {
	return m.start(machinestate.NotInitialized, machinestate.Terminating, machinestate.Terminated)
}
