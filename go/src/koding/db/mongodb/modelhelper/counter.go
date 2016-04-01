package modelhelper

import (
	"koding/db/models"
	"sort"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const (
	CountersColl          = "jCounters"
	CounterContructorName = "JCounter"

	CounterStacks    = "member_stacks"
	CounterInstances = "member_instances"
)

func CreateCounters(counters ...*models.Counter) error {
	v := make([]interface{}, len(counters))

	for i := range v {
		v[i] = counters[i]
	}

	query := func(c *mgo.Collection) error {
		return c.Insert(v...)
	}

	return Mongo.Run(CountersColl, query)
}

func CountersByNamespace(group string) ([]*models.Counter, error) {
	var c []*models.Counter

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"namespace": group}).All(&c)
	}

	if err := Mongo.Run(CountersColl, query); err != nil {
		return nil, err
	}

	sort.Sort(models.Counters(c))

	return c, nil
}

func CounterByID(id bson.ObjectId) (*models.Counter, error) {
	var counter models.Counter

	query := func(c *mgo.Collection) error {
		return c.FindId(id).One(&counter)
	}

	if err := Mongo.Run(CountersColl, query); err != nil {
		return nil, err
	}

	return &counter, nil
}

func DecrementOrCreateCounter(group, typ string, n int) error {
	query := func(c *mgo.Collection) error {
		// Try to decrement the counter only if it won't go negative.
		err := c.Update(
			bson.M{
				"namespace": group,
				"type":      typ,
				"current": bson.M{
					"$gte": n,
				},
			},
			bson.M{
				"$inc": bson.M{
					"current": -n,
				},
			},
		)

		// Most likely n is larger than current counter value, set it to 0.
		if err == mgo.ErrNotFound {
			err = c.Update(
				bson.M{
					"namespace": group,
					"type":      typ,
				},
				bson.M{
					"$set": bson.M{
						"current": 0,
					},
				},
			)
		}

		// Most likely counter for given team does not exist, create it.
		if err == mgo.ErrNotFound {
			err = c.Insert(&models.Counter{
				ID:        bson.NewObjectId(),
				Namespace: group,
				Type:      typ,
				Current:   0,
			})
		}

		return err
	}

	return Mongo.Run(CountersColl, query)
}

func UpdateCounters(group string, stacks, instances int) error {
	query := func(c *mgo.Collection) error {
		stackSel := bson.M{
			"namespace": group,
			"type":      CounterStacks,
		}

		stackUpdate := bson.M{
			"$inc": bson.M{
				"current": stacks,
			},
		}

		instanceSel := bson.M{
			"namespace": group,
			"type":      CounterInstances,
		}

		instanceUpdate := bson.M{
			"$inc": bson.M{
				"current": instances,
			},
		}

		return nonil(
			c.Update(stackSel, stackUpdate),
			c.Update(instanceSel, instanceUpdate),
		)
	}

	return Mongo.Run(CountersColl, query)
}
