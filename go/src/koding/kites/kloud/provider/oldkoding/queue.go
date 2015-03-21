package oldkoding

import (
	"errors"
	"time"

	"github.com/koding/kite"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// RunChecker runs the checker every given interval time. It fetches a single
// document.
func (p *Provider) RunChecker(interval time.Duration) {
	for _ = range time.Tick(interval) {
		// do not block the next tick
		go func() {
			machine, err := p.FetchOne()
			if err != nil {
				// do not show an error if the query didn't find anything, that
				// means there is no such a document, which we don't care
				if err != mgo.ErrNotFound {
					p.Log.Warning("FetchOne err: %v", err)
				}

				// move one with the next one
				return
			}

			if err := p.CheckUsage(machine); err != nil {
				// only log if it's something else
				if err != kite.ErrNoKitesAvailable {
					p.Log.Error("[%s] check usage of klient kite [%s] err: %v",
						machine.Id.Hex(), machine.IpAddress, err)
				}
			}
		}()
	}
}

// CheckUsage checks a single machine usages patterns and applies certain
// restrictions (if any available). For example it could stop a machine after a
// certain inactivity time.
func (p *Provider) CheckUsage(machineDoc *MachineDocument) error {
	if machineDoc == nil {
		return errors.New("checking machine. document is nil")
	}

	credential := p.GetCredential(machineDoc.Credential)

	// populate a protocol.Machine instance that is needed for the Stop()
	// method
	m := &protocol.Machine{
		Id:          machineDoc.Id.Hex(),
		Username:    machineDoc.Credential, // contains the username for koding provider
		Provider:    machineDoc.Provider,
		Builder:     machineDoc.Meta,
		Credential:  credential.Meta,
		State:       machineDoc.State(),
		IpAddress:   machineDoc.IpAddress,
		QueryString: machineDoc.QueryString,
	}
	m.Domain.Name = machineDoc.Domain

	// will be replaced once we connect to klient in checker.Timeout() we are
	// adding it so it doesn't panic when someone tries to retrieve it
	m.Builder["username"] = "kloud-checker"

	// add a fake eventer, means we are not reporting anyone and prevent also
	// panicing when someone try to call the eventer
	m.Eventer = &eventer.Events{}

	checker, err := p.PlanChecker(m)
	if err != nil {
		return err
	}

	// for now just check for timeout. This will dial the remote klient to get
	// the usage data
	return checker.Timeout()
}

// FetchOne() fetches a single machine document from mongodb that meets the criterias:
//
// 1. belongs to koding provider
// 2. are running
// 3. are not always on machines
// 4. are not assigned to anyone yet (unlocked)
// 5. are not picked up by others yet recently
func (p *Provider) FetchOne() (*MachineDocument, error) {
	machine := &MachineDocument{}
	query := func(c *mgo.Collection) error {
		// check only machines that:
		// 1. belongs to koding provider
		// 2. are running
		// 3. are not always on machines
		// 4. are not assigned to anyone yet (unlocked)
		// 5. are not picked up by others yet recently in last 30 seconds
		//
		// The $ne is used to catch documents whose field is not true including
		// that do not contain that particular field
		egligibleMachines := bson.M{
			"provider":            "koding",
			"status.state":        machinestate.Running.String(),
			"meta.alwaysOn":       bson.M{"$ne": true},
			"assignee.inProgress": bson.M{"$ne": true},
			"assignee.assignedAt": bson.M{"$lt": time.Now().UTC().Add(-time.Second * 30)},
		}

		// update so we don't pick up recent things
		update := mgo.Change{
			Update: bson.M{
				"$set": bson.M{
					"assignee.assignedAt": time.Now().UTC(),
				},
			},
		}

		// We sort according to the latest assignment date, which let's us pick
		// always the oldest one instead of random/first. Returning an error
		// means there is no document that matches our criteria.
		// err := c.Find(egligibleMachines).Sort("assignee.assignedAt").One(&machine)
		_, err := c.Find(egligibleMachines).Sort("assignee.assignedAt").Apply(update, &machine)
		if err != nil {
			return err
		}

		return nil
	}

	if err := p.Session.Run("jMachines", query); err != nil {
		return nil, err
	}

	return machine, nil
}
