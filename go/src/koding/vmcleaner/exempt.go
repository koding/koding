package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentapi"
)

type Exempt func(*models.User, *Warning) bool

// All paid users are exempt.
func IsUserPaid(user *models.User, _ *Warning) bool {
	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		Log.Error("Error fetching account with username: %s", user.Name)
		return false
	}

	paymentclient := paymentapi.New("")
	isPaid, err := paymentclient.IsPaidAccount(account)
	if err != nil {
		Log.Error("Error fetching plan for user: %s, default to paid: %v", user.Name, err)
		return true
	}

	return isPaid
}

// Blocked users don't get an email, but vms get deleted.
func IsUserBlocked(user *models.User, _ *Warning) bool {
	return user.Status == modelhelper.UserStatusBlocked
}

// If user has no vm, don't send email saying their vms will be deleted.
func IsUserVMsEmpty(user *models.User, _ *Warning) bool {
	machines, err := modelhelper.GetMachines(user.ObjectId)
	if err != nil {
		Log.Error("Error fetching vms for user: %s, default to false: %v", user.Name, err)
		return true
	}

	return len(machines) == 0
}

// Make sure enough time has elapsed between emails to user.
func IsTooSoon(user *models.User, w *Warning) bool {
	lastLevel := fmt.Sprintf("%d", w.PreviousLevel())
	lastWarned, ok := user.Inactive.Warnings[lastLevel]
	if !ok {
		return false
	}

	return !lastWarned.Add(w.IntervalSinceLastWarning).UTC().After(now())
}
