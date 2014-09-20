package koding

import (
	"fmt"
	"time"

	"github.com/koding/kloud/kloud"
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
	machine := &Machine{}
	if err := p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&machine)
	}); err == mgo.ErrNotFound {
		return nil, kloud.NewError(kloud.ErrMachineNotFound)
	}

	// do not check for admin users, or if test mode is enabled
	if !IsAdmin(username) {
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
	p.Log.Debug("[%s] storage update request of type '%s' data: %v", id, s.Type, s.Data)

	data := map[string]interface{}{}

	switch s.Type {
	case "build":
		data["queryString"] = s.Data["queryString"]
		data["ipAddress"] = s.Data["ipAddress"]
		data["domain"] = s.Data["domainName"]
		data["meta.instanceId"] = s.Data["instanceId"]
		data["meta.instanceName"] = s.Data["instanceName"]
	case "info":
		data["meta.instanceName"] = s.Data["instanceName"]
	case "start":
		data["ipAddress"] = s.Data["ipAddress"]
		data["domain"] = s.Data["domainName"]
		data["meta.instanceId"] = s.Data["instanceId"]
	case "stop":
		data["ipAddress"] = s.Data["ipAddress"]
	case "domain":
		data["domain"] = s.Data["domainName"]
	case "resize":
		data["ipAddress"] = s.Data["ipAddress"]
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
	p.Log.Info("[%s] updating state to '%v'", id, state)
	return p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.Update(
			bson.M{
				"_id": bson.ObjectIdHex(id),
			},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
				},
			},
		)
	})
}
