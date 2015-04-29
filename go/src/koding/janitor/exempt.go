package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentapi"
)

type Exempt func(*models.User, *Warning) (bool, string, error)

// All paid users are exempt.
func IsUserPaid(user *models.User, _ *Warning) (bool, string, error) {
	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		return false, "", err
	}

	paymentclient := paymentapi.New("")
	isPaid, err := paymentclient.IsPaidAccount(account)

	return isPaid, "IsUserPaid", err
}

// Everyone except 'confirmed' users don't get an email, but vms get deleted.
func IsUserNotConfirmed(user *models.User, _ *Warning) (bool, string, error) {
	notConfirmed := user.Status != modelhelper.UserStatusConfirmed
	return notConfirmed, "IsUserNotConfirmed", nil
}

// If user has no vm, don't send email saying their vms will be deleted.
func IsUserVMsEmpty(user *models.User, _ *Warning) (bool, string, error) {
	machines, err := modelhelper.GetMachinesByUsername(user.Name)
	if err != nil {
		return false, "", err
	}

	return len(machines) == 0, "IsUserVMsEmpty", nil
}

// Make sure enough time has elapsed between emails to user.
func IsTooSoon(user *models.User, w *Warning) (bool, string, error) {
	lastLevel := fmt.Sprintf("%d", w.PreviousLevel())
	lastWarned, ok := user.Inactive.Warnings[lastLevel]
	if !ok {
		return false, "IsTooSoon", nil
	}

	tooSoon := lastWarned.Add(w.IntervalSinceLastWarning).UTC().After(timeNow())
	return tooSoon, "IsTooSoon", nil
}
