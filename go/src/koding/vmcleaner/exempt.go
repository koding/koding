package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentapi"
	"time"
)

type Exempt func(*models.User) bool

// All paid users are exempt.
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

// Blocked users don't get an email, but vms get deleted.
func IsUserBlocked(user *models.User) bool {
	return user.Status == modelhelper.UserStatusBlocked
}

// If user has no vm, don't send email saying their vms will be deleted.
func IsUserVMsEmpty(user *models.User) bool {
	machines, err := modelhelper.GetMachines(user.ObjectId)
	if err != nil {
		// Log.Error("Error fetching vms for user: %s, default to false: %v", user.Name, err)
		return true
	}

	return len(machines) == 0
}

func IsWarningTimeElapsed(user *models.User) bool {
	var interval time.Duration
	var t time.Time

	switch user.Inactive.Warning {
	case 1:
		interval = 30
		t = user.Inactive.WarningTime.One
	case 2:
		interval = 45
		t = user.Inactive.WarningTime.Two
	case 3:
		interval = 52
		t = user.Inactive.WarningTime.Three
	case 4:
		interval = 60
		t = user.Inactive.WarningTime.Four
	}

	if t.Add(time.Hour * 24 * interval).After(time.Now().UTC()) {
		return false
	}

	return true
}
