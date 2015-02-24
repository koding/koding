package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func CreateWorkspaceForMachine(machineUId string) (*models.Workspace, error) {
	workspace := &models.Workspace{
		ObjectId: bson.NewObjectId(), MachineUID: machineUId,
	}

	insertQuery := func(c *mgo.Collection) error {
		return c.Insert(workspace)
	}

	err := modelhelper.Mongo.Run(modelhelper.WorkspaceColl, insertQuery)
	if err != nil {
		return nil, err
	}

	return workspace, nil
}

func DeleteWorkspaceForMachine(machineUId string) error {
	deleteQuery := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"machineUId": machineUId})
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.WorkspaceColl, deleteQuery)
}
