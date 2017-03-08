package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2/bson"
)

func CreateGroup() (*models.Group, error) {
	g := &models.Group{
		Id:                 bson.NewObjectId(),
		Body:               bson.NewObjectId().Hex(),
		Title:              bson.NewObjectId().Hex(),
		Slug:               bson.NewObjectId().Hex(),
		Privacy:            "private",
		Visibility:         "hidden",
		SocialApiChannelId: "0",
		// DefaultChannels holds the default channels for a group, when a user joins
		// to this group, participants will be automatically added to regarding
		// channels
		DefaultChannels: []string{"0"},
	}

	return g, modelhelper.CreateGroup(g)
}
