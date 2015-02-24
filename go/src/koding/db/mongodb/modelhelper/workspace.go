package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var WorkspaceColl = "jWorkspaces"

func GetWorkspaces(accountId bson.ObjectId) ([]*models.Workspace, error) {
	query := bson.M{"originId": accountId}
	return get(query)
}

func GetWorkspacesByChannelIds(ids []string) ([]*models.Workspace, error) {
	query := bson.M{"channelId": bson.M{"$in": ids}}
	return get(query)
}

func GetWorkspacesForMachine(machine *models.Machine) ([]*models.Workspace, error) {
	query := bson.M{"machineUId": machine.Uid}
	return get(query)
}

func get(query bson.M) ([]*models.Workspace, error) {
	workspaces := []*models.Workspace{}

	queryFn := func(c *mgo.Collection) error {
		return c.Find(query).All(&workspaces)
	}

	if err := Mongo.Run(WorkspaceColl, queryFn); err != nil {
		return nil, err
	}

	return workspaces, nil
}
