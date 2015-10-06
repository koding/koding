package queue

import (
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/provider/aws"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func (q *Queue) CheckAWS() {
	machine, err := q.FetchAWS()
	if err != nil {
		// do not show an error if the query didn't find anything, that
		// means there is no such a document, which we don't care
		if err != mgo.ErrNotFound {
			q.Log.Warning("FetchOne AWS err: %v", err)
		}

		// move one with the next one
		return
	}

	if err := q.CheckAWSUsage(machine); err != nil {
		// only log if it's something else
		switch err {
		case kite.ErrNoKitesAvailable,
			kontrol.ErrQueryFieldsEmpty,
			klient.ErrDialingFailed:
		default:
			q.Log.Debug("[%s] check usage of AWS klient kite [%s] err: %v",
				machine.Id.Hex(), machine.IpAddress, err)
		}
	}
}

func (q *Queue) CheckAWSUsage(m *awsprovider.Machine) error {
	q.Log.Debug("Checking AWS machine\n%+v\n", m)
	return nil
}

func (q *Queue) FetchAWS() (*awsprovider.Machine, error) {
	q.Log.Debug("Fetching AWS machine")
	machine := &awsprovider.Machine{}
	query := func(c *mgo.Collection) error {
		// check only machines that:
		// 1. belongs to koding provider
		// 2. are running
		// 3. are not assigned to anyone yet (unlocked)
		// 4. are not picked up by others yet recently in last 30 seconds
		//
		// The $ne is used to catch documents whose field is not true including
		// that do not contain that particular field
		egligibleMachines := bson.M{
			"provider":            "aws",
			"status.state":        machinestate.Running.String(),
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

	if err := q.AwsProvider.DB.Run("jMachines", query); err != nil {
		return nil, err
	}

	return machine, nil
}
