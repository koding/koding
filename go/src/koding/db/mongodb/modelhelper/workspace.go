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
		return c.Find(bson.M{"originId": accountId}).All(&workspaces)
	}

	err := Mongo.Run(WorkspaceColl, query)
	if err != nil {
		return nil, err
	}

	return workspaces, nil
}

// GetWorkspaceByChannelId returns the workspace by channel's id
func GetWorkspaceByChannelId(channelID string) (*models.Workspace, error) {
	workspace := &models.Workspace{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"channelId": channelID}).One(&workspace)
	}

	err := Mongo.Run(WorkspaceColl, query)
	if err != nil {
		return nil, err
	}

	return workspace, nil
}

// CreateWorkspace creates the workspace in mongo
func CreateWorkspace(w *models.Workspace) error {
	query := insertQuery(w)
	return Mongo.Run(WorkspaceColl, query)
}
