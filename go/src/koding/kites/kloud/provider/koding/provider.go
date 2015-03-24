package koding

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsclient"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloudctl/command"
	"koding/kites/kloud/multiec2"
	"koding/kites/kloud/userdata"

	"github.com/fatih/structs"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Provider struct {
	DB         *mongodb.MongoDB
	Log        logging.Logger
	Kite       *kite.Kite
	DNS        *dnsclient.DNS
	EC2Clients *multiec2.Clients
	Userdata   *userdata.Userdata

	// PaymentEndpoint is being used to fetch user plans
	PaymentEndpoint      string
	NetworkUsageEndpoint string
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

	ev, ok := eventer.FromContext(ctx)
	if !ok {
		return nil, errors.New("eventer context is not available")
	}

	// get user model which contains user ssh keys or the list of users that
	// are allowed to use this machine
	user, err := p.getUser(req.Username)
	if err != nil {
		return nil, err
	}

	machine.Log = p.Log.New(id)
	if machine.Meta.Region == "" {
		machine.Meta.Region = "us-east-1"
		machine.Log.Critical("region is not set in. Fallback to us-east-1.")
	}

	client, err := p.EC2Clients.Region(machine.Meta.Region)
	if err != nil {
		return nil, err
	}

	amazonClient, err := amazon.New(structs.Map(machine.Meta), client)
	if err != nil {
		return nil, fmt.Errorf("koding-amazon err: %s", err)
	}

	payment, err := p.FetchPlan(user.Name)
	if err != nil {
		machine.Log.Warning("username: %s could not fetch plan. Fallback to Free plan. err: '%s'",
			machine.Username, err)
		payment = &PaymentResponse{Plan: Free}
	}

	machine.networkUsageEndpoint = p.NetworkUsageEndpoint
	machine.Payment = payment
	machine.Username = user.Name
	machine.User = user
	machine.Session = &session.Session{
		DB:         p.DB,
		Kite:       p.Kite,
		DNS:        p.DNS,
		Userdata:   p.Userdata,
		Eventer:    ev,
		AWSClient:  amazonClient,
		AWSClients: p.EC2Clients, // used to fallback if something goes wrong
	}
	machine.cleanFuncs = make([]func(), 0)

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
	if r.Auth != nil {
		if r.Auth.Key == command.KloudSecretKey {
			return nil
		}
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
