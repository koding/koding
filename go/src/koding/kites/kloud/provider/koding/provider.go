package koding

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/pkg/multiec2"
	"koding/kites/kloud/plans"
	"koding/kites/kloud/userdata"
	"time"

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
	DNSClient  *dnsclient.Route53
	DNSStorage *dnsstorage.MongodbStorage
	EC2Clients *multiec2.Clients
	Userdata   *userdata.Userdata

	PaymentFetcher plans.PaymentFetcher
	CheckerFetcher plans.CheckerFetcher

	AuthorizedUsers map[string]string
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

	if machine.Meta.Region == "" {
		machine.Meta.Region = "us-east-1"
		p.Log.Critical("[%s] region is not set in. Fallback to us-east-1.", machine.Id.Hex())
	} else {
		p.Log.Debug("[%s] using region: %s", machine.Id.Hex(), machine.Meta.Region)
	}

	if err := p.attachSession(ctx, machine); err != nil {
		return nil, err
	}

	// check for validation and permission
	if err := p.validate(machine, req); err != nil {
		return nil, err
	}

	return machine, nil
}

func (p *Provider) attachSession(ctx context.Context, machine *Machine) error {
	// get user model which contains user ssh keys or the list of users that
	// are allowed to use this machine
	if len(machine.Users) == 0 {
		return errors.New("permitted users list is empty")
	}

	// check if this is called via Kite call
	var requesterUsername string
	req, ok := request.FromContext(ctx)
	if ok {
		requesterUsername = req.Username
	}

	// get the user from the permitted list. If the list contains more than one
	// allowed person, fetch the one that is the same as requesterUsername, if
	// not pick up the first one.
	user, err := p.getOwner(requesterUsername, machine.Users)
	if err != nil {
		return err
	}

	client, err := p.EC2Clients.Region(machine.Meta.Region)
	if err != nil {
		return err
	}

	amazonClient, err := amazon.New(structs.Map(machine.Meta), client)
	if err != nil {
		return fmt.Errorf("koding-amazon err: %s", err)
	}

	// attach user specific log
	machine.Log = p.Log.New(machine.Id.Hex())

	sess := &session.Session{
		DB:         p.DB,
		Kite:       p.Kite,
		DNSClient:  p.DNSClient,
		DNSStorage: p.DNSStorage,
		Userdata:   p.Userdata,
		AWSClient:  amazonClient,
		AWSClients: p.EC2Clients, // used for fallback if something goes wrong
		Log:        machine.Log,
	}

	// we use session a lot of in Machine owned methods, so that's why we
	// assign it to a field for easy access
	machine.Session = sess

	// we pass it also to the context, so other packages, such as plans checker
	// can make use of it.
	ctx = session.NewContext(ctx, sess)

	payment, err := p.PaymentFetcher.Fetch(ctx, user.Name)
	if err != nil {
		machine.Log.Warning("username: %s could not fetch plan. Fallback to Free plan. err: '%s'",
			user.Name, err)
		payment = &plans.PaymentResponse{Plan: "free"}
	}

	checker, err := p.CheckerFetcher.Fetch(ctx, payment.Plan)
	if err != nil {
		return err
	}

	machine.Payment = payment
	machine.Username = user.Name
	machine.User = user
	machine.cleanFuncs = make([]func(), 0)
	machine.Checker = checker

	ev, ok := eventer.FromContext(ctx)
	if ok {
		machine.Session.Eventer = ev
	}

	return nil
}

// getOwner returns the owner of the machine, if it's not found it returns an
// error. The requestName is optional, if it's not empty and the the users list
// has more than one valid allowed users, we return the one that matches the
// requesterName.
func (p *Provider) getOwner(requesterName string, users []models.Permissions) (*models.User, error) {
	allowedIds := make([]bson.ObjectId, 0)
	for _, perm := range users {
		// we only going to fetch users that are allowed
		if perm.Sudo && perm.Owner {
			allowedIds = append(allowedIds, perm.Id)
		}
	}

	// nothing found, just return
	if len(allowedIds) == 0 {
		return nil, errors.New("owner not found")
	}

	// if the list contains only one user or if the requesterName is empty,
	// just get the do a short lookup and return the first result.
	if len(allowedIds) == 1 || requesterName == "" {
		var user *models.User
		err := p.DB.Run("jUsers", func(c *mgo.Collection) error {
			return c.FindId(allowedIds[0]).One(&user)
		})

		if err == mgo.ErrNotFound {
			return nil, fmt.Errorf("User with Id not found: %s", allowedIds[0].Hex())
		}
		if err != nil {
			return nil, fmt.Errorf("username lookup error: %v", err)
		}

		return user, nil
	}

	// get the full list of users and return the one that matches the
	// requesterName, if not we return someone that is allowed. Note that we
	// don't do the validation here, this is only to fetch the user, don't put
	// any validation logic here.
	var allowedUsers []*models.User
	if err := p.DB.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": allowedIds}}).All(&allowedUsers)
	}); err != nil {
		return nil, fmt.Errorf("username lookup error: %v", err)
	}

	// now we have all allowed users, if we have someone that is in match with
	// the requesterName just return it.
	for _, u := range allowedUsers {
		if u.Name == requesterName {
			return u, nil
		}
	}

	// nothing found, just return the first one
	return allowedUsers[0], nil
}

func (p *Provider) validate(m *Machine, r *kite.Request) error {
	m.Log.Debug("validating for method '%s'", r.Method)

	// give access to authorized users immediately
	if r.Auth != nil {
		if _, authorized := p.AuthorizedUsers[r.Auth.Type]; authorized {
			return nil
		}
	}

	if r.Username != m.User.Name {
		return errors.New("username is not permitted to make any action")
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

func (m *Machine) UpdateState(reason string, state machinestate.State) error {
	m.Log.Debug("Updating state to '%v'", state)
	err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.Update(
			bson.M{
				"_id": m.Id,
			},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
					"status.reason":     reason,
				},
			},
		)
	})

	if err != nil {
		return fmt.Errorf("Couldn't update state to '%s' for document: '%s' err: %s",
			state, m.Id.Hex(), err)
	}

	return nil
}
