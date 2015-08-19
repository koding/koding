package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kodingutils"
	"strings"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	KloudTimeout  = time.Second * 10
	DefaultReason = "NetworkOut limit reached"
)

// request arguments
type requestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
	Provider  string `json:"provider"`
}

func stopVMIfRunning(machineId, username, reason string) error {
	var machine *models.Machine

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.ObjectIdHex(machineId)}).One(&machine)
	}

	if err := modelhelper.Mongo.Run(modelhelper.MachinesColl, query); err != nil {
		return err
	}

	if controller.KiteClient == nil {
		Log.Info("KloudClient not initialized. Not stopping: %s", machineId)
		return nil
	}

	Log.Info("Starting to stop machine: '%s' for username: '%s'", machineId, username)

	_, err := controller.KiteClient.TellWithTimeout("stop", KloudTimeout, &requestArgs{
		MachineId: machineId,
		Reason:    DefaultReason,
		Provider:  "koding",
	})

	if err != nil {
		// kloud ouptuts log for vms already stopped, we don't care
		if strings.Contains(err.Error(), "not allowed for current state") {
			return nil
		}
	}

	return err
}

func blockUserAndDestroyVm(machineId, username, reason string) error {
	return kodingutils.BlockUser(controller.KiteClient, username, DefaultReason, BlockDuration)
}
