package main

import (
	"koding/db/mongodb/modelhelper"
	"strings"
)

// request arguments
type requestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
}

func stopVm(machineId, username, reason string) error {
	if controller.Klient == nil {
		Log.Debug("Klient not initialized. Not stopping: %s", machineId)
		return nil
	}

	_, err := controller.Klient.Tell("stop", &requestArgs{
		MachineId: machineId, Reason: reason,
	})

	// kloud ouptuts log for vms already stopped, we don't care
	if strings.Contains(err.Error(), "not allowed for current state") {
		return nil
	}

	return err
}

func blockUserAndDestroyVm(machineId, username, reason string) error {
	machines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return err
	}

	if controller.Klient != nil {
		for _, machine := range machines {
			_, err := controller.Klient.Tell("stop", &requestArgs{
				MachineId: machine.ObjectId.Hex()},
			)

			if err != nil {
				Log.Error(err.Error())
			}
		}
	} else {
		Log.Debug("Klient not initialized. Not stopping: %s...but blocking user", machineId)
	}

	return modelhelper.BlockUser(username, reason, BlockDuration)
}
