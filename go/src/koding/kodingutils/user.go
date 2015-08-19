package kodingutils

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/koding/kite"
)

var (
	KodingProvider = "koding"
	KloudTimeout   = 10 * time.Second
)

type kloudRequestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
	Provider  string `json:"provider"`
}

// IsKodingOwnedVM return if user is Koding employee.
func IsKodingEmployee(username string) (bool, error) {
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return false, err
	}

	for _, flag := range account.GlobalFlags {
		if flag == models.AccountFlagStaff {
			return true, nil
		}
	}

	return false, nil
}

func BlockUser(kiteClient *kite.Client, username, reason string) error {
	machines, err := modelhelper.GetMachinesByUsername(username)
	if err != nil {
		return err
	}

	var errs *multierror.Error

	for _, machine := range machines {
		if machine.Status.State != "Running" {
			errs = multierror.Append(errs,
				fmt.Errorf("Machine: '%s' has status: '%s'...skipping", machine.ObjectId, machine.Status.State),
			)
			continue
		}

		isKodingOwned, err := IsKodingOwnedVM(machine.ObjectId)
		if err != nil {
			errs = multierror.Append(errs,
				fmt.Errorf("Error fetching provider for VM to stop it: %s", err),
			)
			continue
		}

		if isKodingOwned {
			errs = multierror.Append(errs,
				fmt.Errorf("Machine: '%s' has provider: '%s'...skipping", machine.ObjectId, machine.Provider),
			)
			continue
		}

		_, err = kiteClient.TellWithTimeout("stop", KloudTimeout, &kloudRequestArgs{
			MachineId: machine.ObjectId.Hex(),
			Reason:    reason,
			Provider:  KodingProvider,
		})

		if err != nil {
			errs = multierror.Append(errs,
				fmt.Errorf("Failed to stop machine: '%s' for username: '%s' due to: %s", machine.ObjectId, username, err),
			)
		}
	}

	return nil
}
