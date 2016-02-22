package modelhelper

import (
	"koding/db/models"

	"gopkg.in/mgo.v2"
)

const GatherErrorsColl = "gathererrors"

func SaveGatherError(g *models.GatherError) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(g)
	}

	return Mongo.Run(GatherErrorsColl, query)
}
