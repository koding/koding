package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/workers/email/emailsender"
	"strings"
	"time"
)

var (
	subjects = map[int]string{
		1: "inactive user warning1 v1",
		2: "inactive user warning2 v1",
	}
)

type Action func(*models.User, int) error

func SendEmail(user *models.User, levelId int) error {
	subject, ok := subjects[levelId]
	if !ok {
		return ErrSubjectNotFound
	}

	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		return err
	}

	mail := &emailsender.Mail{
		To:      user.Email,
		Subject: subject,
		Properties: &emailsender.Properties{
			Username: user.Name,
			Options: map[string]interface{}{
				"firstName": account.Profile.FirstName,
			},
		},
	}

	return emailsender.Send(mail)
}

type requestArgs struct {
	MachineId string `json:"machineId"`
}

func DeleteVMs(user *models.User, _ int) error {
	machines, err := modelhelper.GetMachinesByUsername(user.Name)
	if err != nil {
		return err
	}

	if KiteClient == nil {
		return ErrKloudKlientNotInitialized
	}

	for _, machine := range machines {
		// avoid spamming kloud
		time.Sleep(time.Millisecond * time.Duration(rand.Intn(100)))

		_, err := KiteClient.Tell("destroy", &requestArgs{
			MachineId: machine.ObjectId.Hex(),
		})

		if err != nil && !isVmAlreadyStoppedErr(err) {
			Log.Error("Error destroying machine:%s for username: %s, %v", user.Name,
				machine.ObjectId, err)
		}
	}

	return nil
}

func isVmAlreadyStoppedErr(err error) bool {
	return err != nil && strings.Contains(err.Error(), "already stopped")
}
