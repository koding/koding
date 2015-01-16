package payment

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentmodels"
)

type requestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
}

func stopMachinesForUser(providerCustomerId string) error {
	customer := paymentmodels.NewCustomer()
	err := customer.ByProviderCustomerId(providerCustomerId)
	if err != nil {
		return err
	}

	username := customer.Username
	if isUsernameEmpty(username) {
		return errUsernameEmpty(username)
	}

	machines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return err
	}

	if KiteClient == nil {
		Log.Debug("Klient not initialized. Not stopping machines for user: %s",
			username,
		)

		return nil
	}

	for _, machine := range machines {
		_, err := KiteClient.Tell("stop", &requestArgs{
			MachineId: machine.ObjectId.Hex(), Reason: "Plan expired",
		})

		if err != nil {
			Log.Error("Error stopping machine:%s for username: %s, %v", username, machine, err)
		}
	}

	return nil
}
