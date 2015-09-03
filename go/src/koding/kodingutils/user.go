package kodingutils

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/koding/kite"
)

var (
	KodingProvider = "koding"
	KloudTimeout   = 10 * time.Second
)

type kloudRequestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
	Provider  string `json:"provider"`
}

// IsKodingOwnedVM return if user is Koding employee.
func IsKodingEmployee(username string) (bool, error) {
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

// BlockUser blocks user, stops their Koding VMs and removes sessions.
func BlockUser(kiteClient *kite.Client, username, reason string, d time.Duration) error {
	if err := StopVM(kiteClient, username, reason); err != nil {
		return err
	}

	selector := bson.M{"username": username}
	updateQuery := bson.M{"$set": bson.M{
		"status":        modelhelper.UserStatusBlocked,
		"blockedReason": reason,
		"blockedUntil":  time.Now().UTC().Add(d),
	}}

	query := func(c *mgo.Collection) error {
		return c.Update(selector, updateQuery)
	}

	if err := modelhelper.Mongo.Run(modelhelper.UserColl, query); err != nil {
		return err
	}

	return modelhelper.RemoveSession(username)
}

// StopVM gets list of running Koding owned VMs for user and stops them.
func StopVM(kiteClient *kite.Client, username, reason string) error {
	machines, err := modelhelper.GetKodingRunningVMs(username)
	if err != nil {
		return err
	}

	var errs *multierror.Error

	for _, machine := range machines {
		_, err = kiteClient.TellWithTimeout("stop", KloudTimeout, &kloudRequestArgs{
			MachineId: machine.ObjectId.Hex(),
			Reason:    reason,
			Provider:  KodingProvider,
		})

		if err != nil {
			errs = multierror.Append(errs,
				fmt.Errorf("Error stopping machine: '%s' for username: '%s' due to: '%s'", machine.ObjectId, username, err),
			)
		}
	}

	return errs.ErrorOrNil()
}
