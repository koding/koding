package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func GetGatherErrorsForUser(username string) ([]models.GatherError, error) {
	stats := make([]models.GatherError, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(bson.M{"username": username}).Iter()

		var stat models.GatherError
		for iter.Next(&stat) {
			stats = append(stats, stat)
		}

		return iter.Close()
	}

	return stats, modelhelper.Mongo.Run(modelhelper.GatherErrorsColl, query)
}

func DeleteGatherErrorsForUser(username string) error {
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"username": username})
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.GatherErrorsColl, query)
}
