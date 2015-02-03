package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentapi"
)

type Exempt func(*models.User) bool

// All paid users are exempt
func IsUserPaid(user *models.User) bool {
	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		// Log.Error("Error fetching account with username: %s", user.Name)
		return false
	}

	paymentclient := paymentapi.New("")
	yes, err := paymentclient.IsPaidAccount(account)
	if err != nil {
		// Log.Error("Error fetching plan for user: %s, default to paid: %v", user.Name, err)
		return true
	}

	return yes
}

// Blocked users don't get an email, but vms get deleted
func IsUserBlocked(user *models.User) bool {
	return user.Status == modelhelper.UserStatusBlocked
}

func IsUserVMsEmpty(user *models.User) bool {
	machines, err := modelhelper.GetMachines(user.ObjectId)
	if err != nil {
		// Log.Error("Error fetching vms for user: %s, default to false: %v", user.Name, err)
		return true
	}

	if len(machines) > 0 {
		return false
	}

	return true
}
