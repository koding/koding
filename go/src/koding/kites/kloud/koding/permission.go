package koding

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// admins have full control over all methods
var admins = []string{"kloud", "koding"}

// isAdmin checks whether the given username is an admin or not
func IsAdmin(username string) bool {
	for _, admin := range admins {
		if admin == username {
			return true
		}
	}

	return false
}

// checkUser checks whether the given username is available in the users list
// and has permission
func (p *Provider) checkUser(username string, users []models.Permissions) error {
	var user *models.User
	err := p.Session.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&user)
	})

	if err == mgo.ErrNotFound {
		return fmt.Errorf("permission denied. username not found: %s", username)
	}

	if err != nil {
		return fmt.Errorf("permission denied. username lookup error: %v", err)
	}

	// check if the incoming user is in the list of permitted user list
	for _, u := range users {
		if user.ObjectId == u.Id {
			return nil // ok he/she is good to go!
		}
	}

	return fmt.Errorf("permission denied. user %s is not in the list of permitted users", username)
}
