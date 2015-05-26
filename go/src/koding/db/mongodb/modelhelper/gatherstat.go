package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
)

var (
	GatherStatsColl = "gatherstats"
)

func SaveGatherStat(g *models.GatherStat) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(g)
	}

	return Mongo.Run(GatherStatsColl, query)
}
