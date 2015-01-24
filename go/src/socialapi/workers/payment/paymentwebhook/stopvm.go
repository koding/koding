package main

import "github.com/koding/kite"

type requestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
}

func stopMachinesForUser(customerId string, k *kite.Kite) error {
	// customer := paymentmodels.NewCustomer()
	// err := customer.ByProviderCustomerId(customerId)
	// if err != nil {
	//   return err
	// }

	// username := customer.Username
	// if isUsernameEmpty(username) {
	//   return errUsernameEmpty(username)
	// }

	// machines, err := modelhelper.GetMachinesForUsername(username)
	// if err != nil {
	//   return err
	// }

	// if k == nil {
	//   fmt.Println("Klient not initialized. Not stopping machines for user: %s",
	//     username,
	//   )

	//   return nil
	// }

	// for _, machine := range machines {
	//   _, err := k.Tell("stop", &requestArgs{
	//     MachineId: machine.ObjectId.Hex(), Reason: "Plan expired",
	//   })

	//   if err != nil {
	//     fmt.Println("Error stopping machine:%s for username: %s, %v", username, machine, err)
	//   }
	// }

	return nil
}
