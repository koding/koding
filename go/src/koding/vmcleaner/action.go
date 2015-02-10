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

var (
	// Sendgrid template ids.
	templates = map[int]string{
		1: "8239b8ac-032d-4f90-80de-a144519a945c",
		2: "a987a9c0-f116-4e75-bf18-bff3c1c11b37",
		3: "fedf1228-4624-4c23-8dea-e9391c5d1e98",
	}
)

func SendEmail(user *models.User, levelId int) error {
	templateId, ok := templates[levelId]
	if !ok {
		return fmt.Errorf("template not found for level: %v", levelId)
	}

	return Email.SendTemplateEmail(user.Email, templateId, nil)
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
			Log.Error("Error stopping machine:%s for username: %s, %v", user.Name,
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
