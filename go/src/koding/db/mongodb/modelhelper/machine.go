package modelhelper

import (
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Bongo struct {
	ConstructorName string `json:"constructorName"`
	InstanceId      string `json:"instanceId"`
}

type MachineContainer struct {
	Bongo Bongo    `json:"bongo_"`
	Data  *Machine `json:"data"`
	*Machine
}

func GetMachines(username string) ([]*MachineContainer, error) {
	machines := []*Machine{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"credential": username}).All(&machines)
	}

	err := modelhelper.Mongo.Run("jMachines", query)
	if err != nil {
		return nil, err
	}

	containers := []*MachineContainer{}

	for _, machine := range machines {
		bongo := Bongo{
			ConstructorName: "JMachine",
			InstanceId:      "1", // TODO: what should go here?
		}
		container := &MachineContainer{bongo, machine, machine}

		containers = append(containers, container)
	}

	return containers, nil
}
