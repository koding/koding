package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentapi"
)

type Exempt func(*models.User) bool

// All paid users are exempt
func PaidUserExempt(user *models.User) bool {
	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		// Log.Error("Error fetching account with username: %s", user.Name)
		return false
	}

	yes, err := paymentapi.IsPaidAccount(account)
	if err != nil {
		// Log.Error("Error fetching plan, default to paid: %v", err)
		return true
	}

	return yes
}

// Blocked users don't get an email, but vms get deleted
func BlockedUserExempt(user *models.User) bool {
	return user.Status == modelhelper.UserStatusBlocked
}
