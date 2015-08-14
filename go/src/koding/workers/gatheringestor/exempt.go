package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo/bson"
)

// Koding employees are exempt from having their machines stopped.
func isKodingEmployee(username string) (bool, error) {
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

// Only Koding owned VMs are eligible to be stopped.
func isKodingOwnedVM(id bson.ObjectId) (bool, error) {
	machine, err := modelhelper.GetMachine(id)
	if err != nil {
		return false, err
	}

	return machine.Provider == models.MachineKodingProvider, nil
}
