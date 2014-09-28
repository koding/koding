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
func (p *Provider) checkUser(userId bson.ObjectId, users []models.Permissions) error {
	// check if the incoming user is in the list of permitted user list
	for _, u := range users {
		if userId == u.Id {
			return nil // ok he/she is good to go!
		}
	}

	return fmt.Errorf("permission denied. user not in the list of permitted users")
}

func (p *Provider) getUser(username string) (*models.User, error) {
	var user *models.User
	err := p.Session.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&user)
	})

	if err == mgo.ErrNotFound {
		return nil, fmt.Errorf("username not found: %s", username)
	}
	if err != nil {
		return nil, fmt.Errorf("username lookup error: %v", err)
	}

	return user, nil
}
