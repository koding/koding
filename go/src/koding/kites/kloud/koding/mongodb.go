package koding

import (
	"fmt"
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

	machine := &Machine{}
	err := p.Session.Run("jMachines", func(c *mgo.Collection) error {
		// we use findAndModify() to get a unique lock from the DB. That means only
		// one instance should be responsible for this action. We will update the
		// assignee if none else is doing stuff with it.
		change := mgo.Change{
			Update: bson.M{
				"$set": bson.M{
					"assignee.inProgress": true,
					"assignee.assignedAt": time.Now().UTC(),
				},
			},
			ReturnNew: true,
		}

		// if Find() is successful the Update() above will be applied (which
		// set's us as assignee by marking the inProgress to true). If not, it
		// means someone else is working on this document and we should return
		// with an error. The whole process is atomic and a single transaction.
		_, err := c.Find(
			bson.M{
				"_id": bson.ObjectIdHex(id),
				"assignee.inProgress": false,
			},
		).Apply(change, &machine)
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

	// do not check for admin users, or if test mode is enabled
	if !isAdmin(username) {
		// check for user permissions
		if err := p.checkUser(username, machine.Users); err != nil && !p.Test {
			return nil, err
		}
	}

	credential := p.GetCredential(machine.Credential)

	m := &protocol.Machine{
		MachineId:   id,
		Provider:    machine.Provider,
		Builder:     machine.Meta,
		Credential:  credential.Meta,
		State:       machine.State(),
		CurrentData: machine,
	}

	// this can be used by other providers if there is a need.
	if _, ok := m.Builder["username"]; !ok {
		m.Builder["username"] = username
	}

	return m, nil
}

func (p *Provider) GetCredential(publicKey string) *Credential {
	credential := &Credential{}
	// we neglect errors because credential is optional
	p.Session.Run("jCredentialDatas", func(c *mgo.Collection) error {
		return c.Find(bson.M{"publicKey": publicKey}).One(credential)
	})

	return credential
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
					"status.modifiedAt": time.Now().UTC(),
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
			bson.M{"$set": bson.M{"assignee.inProgress": false}},
		)
	})
}
