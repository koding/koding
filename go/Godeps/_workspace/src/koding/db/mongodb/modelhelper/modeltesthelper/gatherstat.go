package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func GetGatherStatsForUser(username string) ([]models.GatherStat, error) {
	stats := make([]models.GatherStat, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(bson.M{"username": username}).Iter()

		var stat models.GatherStat
		for iter.Next(&stat) {
			stats = append(stats, stat)
		}

		return iter.Close()
	}

	return stats, modelhelper.Mongo.Run(modelhelper.GatherStatsColl, query)
}

func DeleteGatherStatsForUser(username string) error {
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"username": username})
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.GatherStatsColl, query)
}
