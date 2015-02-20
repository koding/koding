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
	query := bson.M{"originId": accountId}
	return get(query)
}

func GetWorkspacesForMachine(machineId bson.ObjectId) ([]*models.Workspace, error) {
	query := bson.M{"machineUId": bson.M{"$in": machineId}}
	return get(query)
}

func get(query bson.M) ([]*models.Workspace, error) {
	workspaces := []*models.Workspace{}

	queryFn := func(c *mgo.Collection) error {
		return c.Find(query).All(&workspaces)
	}

	err := Mongo.Run(WorkspaceColl, queryFn)
	if err != nil {
		return nil, err
	}

	return workspaces, nil
}
