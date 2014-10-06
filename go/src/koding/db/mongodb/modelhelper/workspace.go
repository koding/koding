package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func GetWorkspaces(accountId string) ([]*Workspace, error) {
	workspaces := []*models.Workspace{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"owner": accountId}).All(&workspaces)
	}

	err := modelhelper.Mongo.Run("jWorkspaces", query)
	if err != nil {
		return nil, err
	}

	return workspaces, nil
}
