package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
)

var (
	GatherErrorsColl = "gathererrors"
)

func SaveGatherError(g *models.GatherError) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(g)
	}

	return Mongo.Run(GatherErrorsColl, query)
}
