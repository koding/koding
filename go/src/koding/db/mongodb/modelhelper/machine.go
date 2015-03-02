package modelhelper

import (
	"errors"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Bongo struct {
	ConstructorName string `json:"constructorName"`
	InstanceId      string `json:"instanceId"`
}

type MachineContainer struct {
	Bongo Bongo           `json:"bongo_"`
	Data  *models.Machine `json:"data"`
	*models.Machine
}

var (
	MachineColl            = "jMachines"
	MachineConstructorName = "JMachine"
)

func GetMachines(userId bson.ObjectId) ([]*MachineContainer, error) {
	machines := []*models.Machine{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"users.id": userId}).All(&machines)
	}

	err := Mongo.Run(MachineColl, query)
	if err != nil {
		return nil, err
	}

	containers := []*MachineContainer{}

	for _, machine := range machines {
		bongo := Bongo{
			ConstructorName: MachineConstructorName,
			InstanceId:      machine.ObjectId.Hex(),
		}
		container := &MachineContainer{bongo, machine, machine}

		containers = append(containers, container)
	}

	return containers, nil
}

var (
	MachineStateRunning = "Running"
)

func GetRunningVms() ([]*models.Machine, error) {
	query := bson.M{"status.state": MachineStateRunning}
	return findMachine(query)
}

func GetMachinesByUsername(username string) ([]*models.Machine, error) {
	user, err := GetUser(username)
	if err != nil {
		return nil, err
	}

	query := bson.M{"users": bson.M{
		"$elemMatch": bson.M{"id": user.ObjectId, "owner": true},
	}}

	return findMachine(query)
}

func GetOwnMachines(userId bson.ObjectId) ([]*MachineContainer, error) {
	query := bson.M{"users": bson.M{
		"$elemMatch": bson.M{"id": userId, "owner": true},
	}}

	return findMachineContainers(query)
}

func GetSharedMachines(userId bson.ObjectId) ([]*MachineContainer, error) {
	query := bson.M{"users": bson.M{
		"$elemMatch": bson.M{"id": userId, "owner": false, "permanent": true},
	}}

	return findMachineContainers(query)
}

func GetCollabMachines(userId bson.ObjectId) ([]*MachineContainer, error) {
	query := bson.M{"users": bson.M{
		"$elemMatch": bson.M{"id": userId, "owner": false,
			"permanent": bson.M{"$ne": true}},
	}}

	return findMachineContainers(query)
}

func findMachineContainers(query bson.M) ([]*MachineContainer, error) {
	machines, err := findMachine(query)
	if err != nil {
		return nil, err
	}

	containers := []*MachineContainer{}

	for _, machine := range machines {
		bongo := Bongo{
			ConstructorName: MachineConstructorName,
			InstanceId:      "1", // TODO: what should go here?
		}

		container := &MachineContainer{bongo, machine, machine}
		containers = append(containers, container)
	}

	return containers, nil
}

// GetMachineByUid returns the machine by its uid field
func GetMachineByUid(uid string) (*models.Machine, error) {
	machine := &models.Machine{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"uid": uid}).One(machine)
	}

	err := Mongo.Run(MachineColl, query)
	if err != nil {
		return nil, err
	}

	return machine, nil
}

// UnshareMachineByUid unshares the machine from all other users except the
// owner
func UnshareMachineByUid(uid string) error {
	machine, err := GetMachineByUid(uid)
	if err != nil {
		return err
	}

	owner := make([]models.MachineUser, 1)
	for _, user := range machine.Users {
		// this is the correct way to remove all users but the owner from a
		// machine
		if user.Sudo && user.Owner {
			owner[0] = user
			break
		}
	}

	if len(owner) == 0 {
		return errors.New("owner couldnt found")
	}

	s := Selector{"_id": machine.ObjectId}
	o := Selector{"$set": Selector{
		"users": owner,
	}}

	query := func(c *mgo.Collection) error {
		return c.Update(s, o)
	}

	return Mongo.Run(MachineColl, query)
}

func findMachine(query bson.M) ([]*models.Machine, error) {
	machines := []*models.Machine{}

	queryFn := func(c *mgo.Collection) error {
		iter := c.Find(query).Iter()

		var machine models.Machine
		for iter.Next(&machine) {
			var newMachine models.Machine
			newMachine = machine

			machines = append(machines, &newMachine)
		}

		return iter.Close()
	}

	if err := Mongo.Run(MachineColl, queryFn); err != nil {
		return nil, err
	}

	return machines, nil
}

func UpdateMachineAlwaysOn(machineId bson.ObjectId, alwaysOn bool) error {
	query := func(c *mgo.Collection) error {
		return c.Update(
			bson.M{"_id": machineId},
			bson.M{"$set": bson.M{"meta.alwaysOn": alwaysOn}},
		)
	}

	return Mongo.Run(MachineColl, query)
}

func CreateMachine(m *models.Machine) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(m)
	}

	return Mongo.Run(MachineColl, query)
}

// DeleteMachine deletes the machine from mongodb, it is here just for cleaning
// purposes(after tests), machines should not be removed from database  unless
// you are kloud
func DeleteMachine(id bson.ObjectId) error {
	selector := bson.M{"_id": id}

	query := func(c *mgo.Collection) error {
		return c.Remove(selector)
	}

	return Mongo.Run(MachineColl, query)
}
