package koding

import (
	"time"

	"koding/kites/kloud/kloud"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func (p *Provider) Lock(id string) error {
	machine := &MachineDocument{}
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

		// if Find() is successful,  the update above will be applied (which
		// set's the assignee by marking the inProgress to true).
		query := c.Find(bson.M{"_id": bson.ObjectIdHex(id)})

		if err := query.One(&machine); err != nil {
			return err
		}

		if machine.Assignee.InProgress {
			return kloud.ErrLockAcquired
		}

		if _, err := query.Apply(change, &machine); err != nil {
			return err
		} // machine is used just used for prevent nil unmarshalling

		return nil
	})

	switch err {
	case nil:
		return nil
	// query didn't matched, means document a document with a relation with
	// jMachine document is out of sync or a jMachine document is deleted
	// manually.
	case mgo.ErrNotFound:
		return kloud.ErrMachineDocNotFound
	// an ongoing event is in progress
	case kloud.ErrLockAcquired:
		return kloud.ErrLockAcquired
	// some other error, this shouldn't be happed
	default:
		p.Log.Error("Storage get error: %s", err.Error())
		return kloud.NewError(kloud.ErrBadState)
	}
}

func (p *Provider) Unlock(id string) {
	p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": bson.M{"assignee.inProgress": false}},
		)
	})
}
