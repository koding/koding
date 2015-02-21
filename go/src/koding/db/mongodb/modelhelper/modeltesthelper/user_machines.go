package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func CreateUserWithMachine() (*models.User, error) {
	user := &models.User{
		ObjectId: bson.NewObjectId(),
		Name:     "randomuser",
	}

	if err := CreateUser(user); err != nil {
		return nil, err
	}

	if _, err := CreateMachineForUser(user.ObjectId); err != nil {
		return nil, err
	}

	return user, nil
}

func CreateMachineForUser(userId bson.ObjectId) (*models.Machine, error) {
	machineUser := models.MachineUser{Id: userId, Owner: true}
	return createMachine(machineUser)
}

func CreateSharedMachineForUser(userId bson.ObjectId) (*models.Machine, error) {
	machineUser := models.MachineUser{
		Id: userId, Owner: false, Permanent: true,
	}

	return createMachine(machineUser)
}

func CreateCollabMachineForUser(userId bson.ObjectId) (*models.Machine, error) {
	machineUser := models.MachineUser{
		Id: userId, Owner: false, Permanent: false,
	}

	return createMachine(machineUser)
}

func createMachine(machineUser models.MachineUser) (*models.Machine, error) {
	machine := &models.Machine{
		ObjectId: bson.NewObjectId(),
		Users:    []models.MachineUser{machineUser},
	}

	insertQuery := func(c *mgo.Collection) error {
		return c.Insert(machine)
	}

	err := modelhelper.Mongo.Run(modelhelper.MachineColl, insertQuery)
	if err != nil {
		return nil, err
	}

	return machine, nil
}
