package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	WorkspaceColl = "jWorkspaces"
)

func GetWorkspaces(accountId bson.ObjectId) ([]*models.Workspace, error) {
	workspaces := []*models.Workspace{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"owner": accountId}).All(&workspaces)
	}

	err := Mongo.Run(WorkspaceColl, query)
	if err != nil {
		return nil, err
	}

	return workspaces, nil
}
