package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func CreateWorkspaceForMachine(account *models.Account, machineUId string) (*models.Workspace, error) {
	workspace := &models.Workspace{
		ObjectId: bson.NewObjectId(), OriginId: account.Id, MachineUID: machineUId,
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

func UpdateWorkspaceChannelId(machineUId, channelId string) error {
	selector := bson.M{"machineUId": machineUId}
	query := bson.M{"$set": bson.M{"channelId": channelId}}

	updateQuery := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(selector, query)
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.WorkspaceColl, updateQuery)
}

func DeleteWorkspaceForMachine(machineUId string) error {
	deleteQuery := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"machineUId": machineUId})
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.WorkspaceColl, deleteQuery)
}
