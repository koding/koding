package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
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

	fmt.Printf("Sending %v to user: %v with subject: %v\n", levelId, user.Name, subject)

	// account, err := modelhelper.GetAccount(user.Name)
	// if err != nil {
	//   return err
	// }

	// mail := &emailsender.Mail{
	//   To:      user.Email,
	//   Subject: subject,
	//   Properties: &emailsender.Properties{
	//     Username: user.Name,
	//     Options: map[string]interface{}{
	//       "firstName": account.Profile.FirstName,
	//     },
	//   },
	// }

	return nil
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

	for _ = range machines {
		fmt.Printf("Deleting machine for user: %v\n", user.Name)

		// // avoid spamming kloud
		// time.Sleep(time.Millisecond * time.Duration(rand.Intn(100)))

		// _, err := KiteClient.Tell("destroy", &requestArgs{
		//   MachineId: machine.ObjectId.Hex(),
		// })

		// if err != nil {
		//   Log.Error("Error destroying machine:%s for username: %s, %v", user.Name,
		//     machine.ObjectId, err)
		// }
	}

	return nil
}
