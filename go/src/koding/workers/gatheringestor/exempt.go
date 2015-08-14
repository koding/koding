package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"github.com/koding/redis"

	"labix.org/v2/mgo/bson"
)

// isKodingOwnedVM return if user is Koding employee.
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

// isKodingEmployee return if VM is owned by Koding.
func isKodingOwnedVM(id bson.ObjectId) (bool, error) {
	machine, err := modelhelper.GetMachine(id)
	if err != nil {
		return false, err
	}

	return machine.Provider == models.MachineKodingProvider, nil
}

// isInExemptList returns if user is in exempt list of users for
// stopping their VMs.
func isInExemptList(conn *redis.RedisSession, username string) (bool, error) {
	i, err := conn.IsSetMember(ExemptUsersKey, username)
	return i == 1, err
}
