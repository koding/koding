package modelhelper

import (
	"koding/db/models"

	"gopkg.in/mgo.v2"
)

const GatherStatsColl = "gatherstats"

func SaveGatherStat(stat *models.GatherStat) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(stat)
	}

	return Mongo.Run(GatherStatsColl, query)
}
