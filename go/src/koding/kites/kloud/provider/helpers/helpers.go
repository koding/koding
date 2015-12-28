package helpers

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloudctl/command"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/kite"
)

func ValidateUser(user *models.User, users []models.MachineUser, r *kite.Request) error {
	// give access to kloudctl immediately
	if r.Auth != nil {
		if r.Auth.Key == command.KloudSecretKey {
			return nil
		}
	}

	if r.Username != user.Name {
		return errors.New("username is not permitted to make any action")
	}

	// check for user permissions
	if err := checkUser(user.ObjectId, users); err != nil {
		return err
	}

	if user.Status != "confirmed" {
		return kloud.NewError(kloud.ErrUserNotConfirmed)
	}

	return nil
}

// checkUser checks whether the given username is available in the users list
// and has permission
func checkUser(userId bson.ObjectId, users []models.MachineUser) error {
	// check if the incoming user is in the list of permitted user list
	for _, u := range users {
		if userId == u.Id && (u.Owner || (u.Permanent && u.Approved)) {
			return nil // ok he/she is good to go!
		}
	}

	return fmt.Errorf("permission denied. user not in the list of permitted users")
}
