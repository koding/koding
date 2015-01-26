package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentmodels"

	"github.com/koding/kite"
)

type requestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
}

func stopMachinesForUser(customerId string, k *kite.Client) error {
	customer := paymentmodels.NewCustomer()
	err := customer.ByProviderCustomerId(customerId)
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

	if k == nil {
		Log.Info("Klient not initialized. Not stopping machines for user: %s",
			username,
		)

		return nil
	}

	for _, machine := range machines {
		_, err := k.Tell("stop", &requestArgs{
			MachineId: machine.ObjectId.Hex(), Reason: "Plan expired",
		})

		if err != nil {
			Log.Error("Error stopping machine:%s for username: %s, %v", username, machine, err)
		}
	}

	return nil
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func isUsernameEmpty(username string) bool {
	return username == ""
}

func errUsernameEmpty(customerId string) error {
	return fmt.Errorf(
		"stopping machine for paypal customer: %s failed since username is empty",
		customerId,
	)
}

func errUnmarshalFailed(data interface{}) error {
	return fmt.Errorf("unmarshalling webhook failed: %v", data)
}
