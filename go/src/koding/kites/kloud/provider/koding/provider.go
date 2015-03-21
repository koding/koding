package koding

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloudctl/command"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Provider struct {
	DB  *mongodb.MongoDB
	Log logging.Logger
}

type Credential struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	PublicKey string        `bson:"publicKey"`
	Meta      bson.M        `bson:"meta"`
}

func (p *Provider) Machine(ctx context.Context, id string) (interface{}, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Invalid machine id: %q", id)
	}

	// let's first check if the id exists, because we are going to use
	// findAndModify() and it would be difficult to distinguish if the id
	// really doesn't exist or if there is an assignee which is a different
	// thing. (Because findAndModify() also returns "not found" for the case
	// where the id exist but someone else is the assignee).
	machine := &Machine{}
	if err := p.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&machine)
	}); err == mgo.ErrNotFound {
		return nil, kloud.NewError(kloud.ErrMachineNotFound)
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not available")
	}

	// get user model which contains user ssh keys or the list of users that
	// are allowed to use this machine
	user, err := p.getUser(req.Username)
	if err != nil {
		return nil, err
	}

	p.Log.Debug("machine: %v", machine)
	p.Log.Debug("request: %v", req)

	machine.Log = p.Log.New(id)
	machine.Username = user.Name
	machine.User = user

	// check for validation and permission
	if err := p.validate(machine, req); err != nil {
		return nil, err
	}

	return machine, nil
}

func (p *Provider) getUser(username string) (*models.User, error) {
	var user *models.User
	err := p.DB.Run("jUsers", func(c *mgo.Collection) error {
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

func (p *Provider) validate(m *Machine, r *kite.Request) error {
	m.Log.Debug("validating for method '%s'", r.Method)

	// give access to kloudctl
	if r.Auth.Key == command.KloudSecretKey {
		return nil
	}

	// check for user permissions
	if err := p.checkUser(m.User.ObjectId, m.Users); err != nil {
		return err
	}

	if m.User.Status != "confirmed" {
		return kloud.NewError(kloud.ErrUserNotConfirmed)
	}

	return nil
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

func (p *Provider) credential(publicKey string) (*Credential, error) {
	credential := &Credential{}
	// we neglect errors because credential is optional
	err := p.DB.Run("jCredentialDatas", func(c *mgo.Collection) error {
		return c.Find(bson.M{"publicKey": publicKey}).One(credential)
	})
	if err != nil {
		return nil, err
	}

	return credential, nil
}
