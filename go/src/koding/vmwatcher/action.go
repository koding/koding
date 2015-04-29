package main

import (
	"koding/db/mongodb/modelhelper"
	"strings"
	"time"
)

var KloudTimeout = time.Second * 2

// request arguments
type requestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
	Provider  string `json:"provider"`
}

func stopVm(machineId, username, reason string) error {
	if controller.Klient == nil {
		Log.Debug("Klient not initialized. Not stopping: %s", machineId)
		return nil
	}

	_, err := controller.Klient.TellWithTimeout("stop", KloudTimeout, &requestArgs{
		MachineId: machineId,
		Reason:    reason,
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
	err := modelhelper.BlockUser(username, reason, BlockDuration)
	if err != nil {
		return err
	}

	machines, err := modelhelper.GetMachinesByUsername(username)
	if err != nil {
		return err
	}

	for _, machine := range machines {
		err := stopVm(machine.ObjectId.Hex(), username, reason)
		if err != nil && !isVmAlreadyStoppedErr(err) {
			Log.Error("Error stopping machine:%s for username: %s, %v", username, machine, err)
		}
	}

	return nil
}

func isVmAlreadyStoppedErr(err error) bool {
	return err != nil && strings.Contains(err.Error(), "already stopped")
}
