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
	var counters []*models.Counter

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"namespace": group}).All(&counters)
	}

	if err := Mongo.Run(CountersColl, query); err != nil {
		return nil, err
	}

	sort.Sort(models.Counters(counters))

	return counters, nil
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
		change := mgo.Change{
			Update: bson.M{
				"$inc": bson.M{
					"current": -n,
				},
			},
			Upsert:    true,
			ReturnNew: true,
		}

		_, err := c.Find(
			bson.M{
				"namespace": group,
				"type":      typ,
				"current": bson.M{
					"$gte": n,
				},
			},
		).Apply(change, nil)

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
