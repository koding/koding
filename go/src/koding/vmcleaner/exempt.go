package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentapi"
)

type Exempt func(*models.User, *Warning) (bool, error)

// All paid users are exempt.
func IsUserPaid(user *models.User, _ *Warning) (bool, error) {
	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		return false, err
	}

	paymentclient := paymentapi.New("")
	return paymentclient.IsPaidAccount(account)
}

// Blocked users don't get an email, but vms get deleted.
func IsUserBlocked(user *models.User, _ *Warning) (bool, error) {
	return user.Status == modelhelper.UserStatusBlocked, nil
}

// If user has no vm, don't send email saying their vms will be deleted.
func IsUserVMsEmpty(user *models.User, _ *Warning) (bool, error) {
	machines, err := modelhelper.GetMachinesByUsername(user.Name)
	if err != nil {
		return false, err
	}

	return len(machines) == 0, nil
}

// Make sure enough time has elapsed between emails to user.
func IsTooSoon(user *models.User, w *Warning) (bool, error) {
	lastLevel := fmt.Sprintf("%d", w.PreviousLevel())
	lastWarned, ok := user.Inactive.Warnings[lastLevel]
	if !ok {
		return false, nil
	}

	return !lastWarned.Add(w.IntervalSinceLastWarning).UTC().After(now()), nil
}
