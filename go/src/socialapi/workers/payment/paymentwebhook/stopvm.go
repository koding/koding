package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentmodels"
	"strings"

	"github.com/koding/kite"
)

type requestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
	Provider  string `json:"provider"`
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

	machines, err := modelhelper.GetMachinesByUsername(username)
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
			MachineId: machine.ObjectId.Hex(),
			Reason:    "Plan expired",
			Provider:  "koding",
		})

		if err != nil && !isVmAlreadyStoppedErr(err) {
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

func isVmAlreadyStoppedErr(err error) bool {
	return err != nil && strings.Contains(err.Error(), "not allowed for current state")
}
