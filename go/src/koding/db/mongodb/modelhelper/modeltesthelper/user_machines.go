package modeltesthelper

import (
	"crypto/rand"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func CreateUserWithMachine(username string) (*models.User, error) {
	user, account, err := CreateUser(username)
	if err != nil {
		return nil, err
	}

	machine, err := CreateMachineForUser(user.ObjectId)
	if err != nil {
		return nil, err
	}

	if _, err := CreateWorkspaceForMachine(account, machine.Uid); err != nil {
		return nil, err
	}

	return user, nil
}

func DeleteMachine(id bson.ObjectId) error {
	deleteQuery := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"_id": id})
	}

	return modelhelper.Mongo.Run(modelhelper.MachineColl, deleteQuery)
}

func CreateMachineForUser(userId bson.ObjectId) (*models.Machine, error) {
	machineUser := models.MachineUser{Id: userId, Owner: true}
	return createMachine(machineUser)
}

func ShareMachineWithUser(machineId, userId bson.ObjectId, p bool) error {
	machineUser := models.MachineUser{
		Id: userId, Owner: false, Permanent: p,
	}

	selector := bson.M{"_id": machineId}
	updateQuery := bson.M{"$push": bson.M{"users": machineUser}}

	query := func(c *mgo.Collection) error {
		return c.Update(selector, updateQuery)
	}

	return modelhelper.Mongo.Run(modelhelper.MachineColl, query)
}

func createMachine(machineUser models.MachineUser) (*models.Machine, error) {
	machine := &models.Machine{
		ObjectId: bson.NewObjectId(),
		Users:    []models.MachineUser{machineUser},
		Uid:      randStr(10),
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

func randStr(size int) string {
	alphanum := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

	bytes := make([]byte, size)
	rand.Read(bytes)

	for i, b := range bytes {
		bytes[i] = alphanum[b%byte(len(alphanum))]
	}

	return string(bytes)
}
