package machine

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/kodingapi/models"

	"golang.org/x/net/context"
)

type machine struct{}

func NewMachine() MachineService {
	return &machine{}
}

// GetMachine returns the machine.
func (m *machine) GetMachine(ctx context.Context, req *string) (*models.Machine, error) {
	machineId := req
	machine, err := modelhelper.GetMachine(*machineId)
	if err != nil {
		return nil, err
	}

	return &models.Machine{
		Owner: machine.Owner().Owner,
	}, nil
}

// GetMachineStatus returns the machine's current status.
func (m *machine) GetMachineStatus(ctx context.Context, req *string) (*models.Machine, error) {
	machineId := req
	machine, err := modelhelper.GetMachine(*machineId)
	if err != nil {
		return nil, err
	}

	// status := machine.State()

	return &models.Machine{
		Owner: machine.Owner().Owner,
		State: machine.Status.State,
	}, nil
}

// ListMachines returns the machine list of the user.
func (m *machine) ListMachines(ctx context.Context, req *string) (*[]*models.Machine, error) {
	auth := ctx.Value("auth")

	userModel, err := modelhelper.GetUserByAccessToken(auth.(string))
	if err != nil {
		return nil, err
	}

	var macs []*models.Machine
	machines, err := modelhelper.GetMachinesByUsername(userModel.Name)
	if err != nil {
		return nil, err
	}

	for _, mac := range machines {
		macs = append(macs, &models.Machine{State: mac.Status.State})
	}

	return &macs, nil
}
