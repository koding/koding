package oldkoding

import (
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloudctl/command"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// admins have full control over all methods
var admins = []string{"kloud", "koding"}

func (p *Provider) Validate(m *protocol.Machine, r *kite.Request) error {
	p.Log.Debug("[%s] validating for method '%s'", m.Id, r.Method)
	username := m.Username

	// do not check for admin users, or if test mode is enabled
	if isAdmin(username) {
		return nil
	}

	// give access to kloudctl
	if r.Auth.Key == command.KloudSecretKey {
		return nil
	}

	// check for user permissions and
	if err := p.checkUser(m.User.ObjectId, m.SharedUsers); err != nil && !p.Test {
		return err
	}

	if m.User.Status != "confirmed" {
		return kloud.NewError(kloud.ErrUserNotConfirmed)
	}

	return nil
}

// isAdmin checks whether the given username is an admin or not
func isAdmin(username string) bool {
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
		if userId == u.Id && u.Owner {
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
