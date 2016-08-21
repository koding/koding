package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"strings"

	"gopkg.in/mgo.v2"
)

var (
	IsUserPaid             = NewChecker("IsUserPaid", IsUserPaidFn)
	IsUserVMsEmpty         = NewChecker("IsUserVMsEmpty", IsUserVMsEmptyFn)
	IsTooSoon              = NewChecker("IsTooSoon", IsTooSoonFn)
	IsUserNotConfirmed     = NewChecker("IsUserNotConfirmed", IsUserNotConfirmedFn)
	IsUserKodingEmployee   = NewChecker("IsKodingEmployee", IsUserKodingEmployeeFn)
	HasMultipleMemberships = NewChecker("HasMultipleMemberships", HasMultipleMembershipsFn)

	// could be overriden in test suites
	kodingGroupName = "koding"
)

type ExemptChecker struct {
	Name     string
	IsExempt func(*models.User, *Warning) (bool, error)
}

func NewChecker(name string, fn func(*models.User, *Warning) (bool, error)) *ExemptChecker {
	return &ExemptChecker{
		Name:     name,
		IsExempt: fn,
	}
}

// IsUserPaidFn checks if user is paid or not. All paid users are exempt.
func IsUserPaidFn(user *models.User, _ *Warning) (bool, error) {
	return false, nil
}

// IsUserNotConfirmedFn checks if user is 'unconfirmed'. Unconfirmed users
// don't get an email, but their vms get deleted.
func IsUserNotConfirmedFn(user *models.User, _ *Warning) (bool, error) {
	notConfirmed := user.Status != modelhelper.UserStatusConfirmed
	return notConfirmed, nil
}

// IsUserVMsEmptyFn checks if user has any vms. If not, we don't send email
// saying their vms will be deleted.
func IsUserVMsEmptyFn(user *models.User, _ *Warning) (bool, error) {
	machines, err := modelhelper.GetMachinesByUsernameAndProvider(
		user.Name, modelhelper.MachineProviderKoding,
	)
	if err != nil {
		return false, err
	}

	return len(machines) == 0, nil
}

// IsTooSoonFn checks enough time has elapsed between emails to user.
func IsTooSoonFn(user *models.User, w *Warning) (bool, error) {
	if w.PreviousWarning == nil {
		return false, nil
	}

	if user.Inactive == nil || user.Inactive.Warnings == nil {
		return false, nil
	}

	lastWarned, ok := user.Inactive.Warnings[w.PreviousWarning.ID]
	if !ok {
		return false, nil
	}

	tooSoon := lastWarned.Add(w.IntervalSinceLastWarning).UTC().After(timeNow())
	return tooSoon, nil
}

// IsUserKodingEmployee checks if user is a Koding employee based on email.
func IsUserKodingEmployeeFn(user *models.User, w *Warning) (bool, error) {
	return strings.HasSuffix(user.Email, "@koding.com"), nil
}

// HasMultipleMemberships checks if user is only Koding group member.
func HasMultipleMembershipsFn(user *models.User, w *Warning) (bool, error) {
	groups, err := modelhelper.FetchAccountGroups(user.Name)
	if err == mgo.ErrNotFound {
		return false, nil
	}

	if err != nil {
		return false, err
	}

	switch len(groups) {
	case 0: // where user is in limbo! delete it
		return false, nil
	case 1: // if belongs only to one group, that should be koding
		if groups[0] != kodingGroupName {
			return true, nil
		}

		return false, nil
	default:
		return true, nil
	}
}
