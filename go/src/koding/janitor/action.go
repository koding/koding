package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"strings"
	"time"
)

type Action func(*models.User, int) error

func SendEmail(user *models.User, levelId int) error {
	return nil
}

// request arguments
type requestArgs struct {
	MachineId string `json:"machineId"`
}

func DeleteVMs(user *models.User, _ int) error {
	machines, err := modelhelper.GetMachinesByUsername(user.Name)
	if err != nil {
		return err
	}

	if KiteClient == nil {
		return fmt.Errorf(
			"Klient not initialized. Not deleting vms for user: %s", user.Name,
		)
	}

	for _, machine := range machines {
		time.Sleep(time.Millisecond * time.Duration(rand.Intn(100)))

		_, err := KiteClient.Tell("destroy", &requestArgs{
			MachineId: machine.ObjectId.Hex(),
		})

		if err != nil && !isVmAlreadyStoppedErr(err) {
			Log.Error("Error destroying machine:%s for username: %s, %v", user.Name,
				machine.ObjectId, err)
		}

		if err != nil {
			Log.Error(err.Error())
		}
	}

	return nil
}

func isVmAlreadyStoppedErr(err error) bool {
	return err != nil && strings.Contains(err.Error(), "already stopped")
}
