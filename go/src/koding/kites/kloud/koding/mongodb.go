package koding

import (
	"fmt"
	"koding/db/models"
	"time"

	"github.com/koding/kloud"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// Assignee returns the assignee responsible for MongoDB actions, in our case
// it's the Kloud name together with hostname and a unique identifier.
func (p *Provider) Assignee() string { return p.AssigneeName }

// Get returns the meta of the associated credential with the given machine id.
func (p *Provider) Get(id, username string) (*protocol.Machine, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Invalid machine id: %q", id)
	}

	// let's first check if the id exists, because we are going to use
	// findAndModify() and it would be difficult to distinguish if the id
	// really doesn't exist or if there is an assignee which is a different
	// thing. (Because findAndModify() also returns "not found" for the case
	// where the id exist but someone else is the assignee).
	if err := p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(nil)
	}); err == mgo.ErrNotFound {
		return nil, kloud.NewError(kloud.ErrMachineNotFound)
	}

	// we use findAndModify() to get a unique lock from the DB. That means only
	// one instance should be responsible for this action. We will update the
	// assignee if none else is doing stuff with it.
	change := mgo.Change{
		Update: bson.M{
			"$set": bson.M{
				"assignee.name": p.Assignee(),
				"assignee.time": time.Now(),
			},
		},
		ReturnNew: true,
	}

	machine := &Machine{}
	err := p.Session.Run("jMachines", func(c *mgo.Collection) error {
		// If Find() is successful the Update() above will be applied
		// (which set's us as assignee). If not, it means someone else is
		// working on this document and we should return with an error. The
		// whole process is Atomic and a single transaction.

		// Now we query for our document. There are two cases:

		// 1.) assigne.name is nil: A nil assignee means that nobody has
		// picked it up yet and we are good to go.

		// 2.) assigne.name is not nil: kloud might crash during the time
		// it has selected the document but couldn't unset assigne.name to
		// nil. If kloud doesn't start (because it cleans documents that
		// belongs to himself at start), assigne.name will be always
		// non-nil. If that instance nevers starts assigne will not changed
		// ever.

		// Therefore we are going to check if it was assigned 10 minutes
		// ago and reassign again. However, we also add an additional check
		// which will prevent multiple readers update the same document. If
		// one is able to query the document the Update() above will update
		// the assignedAt to current date, but the next one will be not
		// able to query it because the second additional date is not valid
		// anymore.
		_, err := c.Find(
			bson.M{
				"_id": bson.ObjectIdHex(id),
				"$or": []bson.M{
					bson.M{"assignee.name": nil},
					bson.M{"$and": []bson.M{
						bson.M{"assignee.assignedAt": bson.M{"$lt": time.Now().Add(time.Minute * 10)}},
						bson.M{"assignee.assignedAt": bson.M{"$lt": time.Now().Add(-time.Second * 30)}},
					}},
				},
			}).Apply(change, &machine)
		return err
	})

	// query didn't matched, means it's assigned to some other Kloud
	// instances and an ongoing event is in process.
	if err == mgo.ErrNotFound {
		return nil, kloud.NewError(kloud.ErrMachinePendingEvent)
	}

	// some other error, this shouldn't be happed
	if err != nil {
		p.Log.Error("Storage get error: %s", err.Error())
		return nil, kloud.NewError(kloud.ErrBadState)
	}

	// check for user permissions
	if err := p.checkUser(username, machine.Users); err != nil && !p.Test {
		return nil, err
	}

	credential := &Credential{}
	// we neglect errors because credential is optional
	p.Session.Run("jCredentialDatas", func(c *mgo.Collection) error {
		return c.Find(bson.M{"publicKey": machine.Credential}).One(credential)
	})

	return &protocol.Machine{
		MachineId:  id,
		Provider:   machine.Provider,
		Builder:    machine.Meta,
		Credential: credential.Meta,
		State:      machine.State(),
	}, nil
}

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

func (p *Provider) Update(id string, s *kloud.StorageData) error {
	p.Log.Debug("[storage] got update request for id '%s' of type '%s'", id, s.Type)

	data := map[string]interface{}{}

	switch s.Type {
	case "build":
		data["queryString"] = s.Data["queryString"]
		data["ipAddress"] = s.Data["ipAddress"]
		data["meta.instanceId"] = s.Data["instanceId"]
		data["meta.instanceName"] = s.Data["instanceName"]
	case "info":
		data["meta.instanceName"] = s.Data["instanceName"]
	case "start":
		data["ipAddress"] = s.Data["ipAddress"]
		data["meta.instanceId"] = s.Data["instanceId"]
		data["meta.instanceName"] = s.Data["instanceName"]
	default:
		return fmt.Errorf("Storage type unknown: '%s'", s.Type)
	}

	return p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": data},
		)
	})
}

func (p *Provider) UpdateState(id string, state machinestate.State) error {
	return p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now(),
				},
			},
		)
	})
}

// ResetAssignee resets the assigne for the given id to nil.
func (p *Provider) ResetAssignee(id string) error {
	return p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": bson.M{"assignee.name": nil}},
		)
	})
}

// CleanupOldData cleans up the assigne name that was bound to this kloud but
// didn't get unset. This happens when the kloud instance crashes before it
// could unset the assigne.name
func (p *Provider) CleanupOldData() error {
	return p.Session.Run("jMachines", func(c *mgo.Collection) error {
		_, err := c.UpdateAll(
			bson.M{"assignee.name": p.Assignee()},
			bson.M{"$set": bson.M{"assignee.name": nil}},
		)
		return err
	})
}
