package main

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/workers/email/emailsender"
	"time"
)

type Action func(*models.User, string) error

var subjects = map[string]string{
	"vmDeletionWarning-1": "received 1st VM deletion warning",
	"vmDeletionWarning-2": "received 2nd VM deletion warning",
}

func SendEmail(user *models.User, warningID string) error {
	subject, ok := subjects[warningID]
	if !ok {
		subject = "unknown warning"
	}

	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		return err
	}

	machines, err := modelhelper.GetMachinesByUsername(user.Name)
	if err != nil {
		return err
	}

	if len(machines) < 1 {
		return errors.New("user has no vms")
	}

	mail := &emailsender.Mail{
		To:      user.Email,
		Subject: subject,
		Properties: &emailsender.Properties{
			Username: user.Name,
			Options: map[string]interface{}{
				"first_name": account.Profile.FirstName,
				"vm_name":    machines[0].Label,
			},
		},
	}

	return emailsender.Send(mail)
}

type requestArgs struct {
	MachineID string `json:"machineId"`
	Provider  string `json:"provider"`
}

func DeleteVMs(user *models.User, _ string) error {
	if KiteClient == nil {
		return ErrKloudKlientNotInitialized
	}

	machines, err := modelhelper.GetMachinesByUsername(user.Name)
	if err != nil {
		return err
	}

	var topErr error

	for _, machine := range machines {
		// avoid spamming kloud
		time.Sleep(time.Millisecond * time.Duration(rand.Intn(500)))

		_, err := KiteClient.Tell("destroy", &requestArgs{
			MachineID: machine.ObjectId.Hex(),
			Provider:  "koding",
		})

		if err != nil {
			topErr = err
			Log.Error("Error destroying machine:%s for username: %s, %v", user.Name,
				machine.ObjectId, err)
		}
	}

	return topErr
}
