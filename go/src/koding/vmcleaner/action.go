package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
)

type Action func(*models.User, int) error

var (
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
	Reason    string `json:"reason"`
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
		_, err := KiteClient.Tell("destroy", &requestArgs{
			MachineId: machine.ObjectId.Hex()},
		)

		if err != nil {
			Log.Error(err.Error())
		}
	}

	return nil
}
