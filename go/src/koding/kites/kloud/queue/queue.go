package queue

import (
	"time"

	"github.com/koding/logging"

	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/provider/aws"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

type Queue struct {
	AwsProvider *awsprovider.Provider
	Log         logging.Logger
}

// RunChecker runs the checker for Koding and AWS providers every given
// interval time. It fetches a single document.
func (q *Queue) RunCheckers(interval time.Duration) {
	q.Log.Debug("queue started with interval %s", interval)

	if q.AwsProvider == nil {
		q.Log.Warning("not running cleaner queue for aws koding provider")
	}

	for _ = range time.Tick(interval) {
		// do not block the next tick
		go q.CheckAWS()
	}
}

// Fetch provider fetches the machine and populates the fields for the given
// provider.
func (q *Queue) FetchProvider(provider string, machine interface{}) error {
	query := func(c *mgo.Collection) error {
		// check only machines that:
		// 1. belongs to the given provider
		// 2. are running
		// 3. are not always on machines
		// 3. are not assigned to anyone yet (unlocked)
		// 4. are not picked up by others yet recently in last 30 seconds
		//
		// The $ne is used to catch documents whose field is not true including
		// that do not contain that particular field
		egligibleMachines := bson.M{
			"provider":            provider,
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
		_, err := c.Find(egligibleMachines).Sort("assignee.assignedAt").Apply(update, machine)
		if err != nil {
			return err
		}

		return nil
	}

	return q.AwsProvider.DB.Run("jMachines", query)
}
