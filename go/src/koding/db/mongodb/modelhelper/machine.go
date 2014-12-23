package modelhelper

import (
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
			InstanceId:      "1", // TODO: what should go here?
		}
		container := &MachineContainer{bongo, machine, machine}

		containers = append(containers, container)
	}

	return containers, nil
}

var (
	VmRunningState = "Running"
)

func GetRunningVms() ([]*models.Machine, error) {
	machines := []*models.Machine{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"status.state": VmRunningState}).All(&machines)
	}

	err := Mongo.Run(MachineColl, query)
	if err != nil {
		return nil, err
	}

	return machines, nil
}
