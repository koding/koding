package machine

import (
	// "koding/db/models"
	"socialapi/workers/kodingapi/models"

	"golang.org/x/net/context"
)

const ServiceName = "machine"

// Machine represents a registered Account's Machine Info
type MachineService interface {
	// GetMachine returns the machine.
	GetMachine(ctx context.Context, req *string) (res *models.Machine, err error)

	// GetMachineStatus returns the machine's current status.
	GetMachineStatus(ctx context.Context, req *string) (res *models.Machine, err error)

	// ListMachines returns the machine list of the user.
	ListMachines(ctx context.Context, req *string) (res *[]*models.Machine, err error)
}
