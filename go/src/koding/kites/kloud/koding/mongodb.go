package koding

import (
	"fmt"
	"time"

	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// Get returns the meta of the associated credential with the given machine id.
func (p *Provider) Get(id string) (*protocol.Machine, error) {
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

	// as a koding provider, the credential is just the username so we can use
	// it directly, otherwise we need to make an additional lookup via
	// jAccounts with machine.Users.Id..
	username := machine.Credential

	// do not check for admin users, or if test mode is enabled
	if !IsAdmin(username) {
		// check for user permissions
		if err := p.checkUser(username, machine.Users); err != nil && !p.Test {
			return nil, err
		}
	}

	credential := p.GetCredential(machine.Credential)

	m := &protocol.Machine{
		Id:          id,
		Username:    machine.Credential, // contains the username for koding provider
		Provider:    machine.Provider,
		Builder:     machine.Meta,
		Credential:  credential.Meta,
		State:       machine.State(),
		IpAddress:   machine.IpAddress,
		QueryString: machine.QueryString,
	}
	m.Domain.Name = machine.Domain

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
