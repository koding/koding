package provider

import (
	"time"

	"koding/db/models"
	"koding/kites/kloud/stack"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func (s *Stacker) Lock(id string) error {
	err := s.DB.Run("jMachines", func(c *mgo.Collection) error {
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
				"assignee.inProgress": bson.M{"$ne": true},
			},
		).Apply(change, &models.Machine{}) // machine is used just used for prevent nil unmarshalling
		return err
	})

	// query didn't matched, means it's assigned to some other Kloud
	// instances and an ongoing event is in process.
	if err == mgo.ErrNotFound {
		return stack.ErrLockAcquired
	}

	// some other error, this shouldn't be happed
	if err != nil {
		s.Log.Error("Storage get error: %s", err)

		return stack.NewError(stack.ErrBadState)
	}

	return nil
}

func (s *Stacker) Unlock(id string) {
	s.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": bson.M{"assignee.inProgress": false}},
		)
	})
}
