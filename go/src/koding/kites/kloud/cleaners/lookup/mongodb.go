package lookup

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// MachineDocument represents a single MongodDB document from the jMachines
// collection.
type MachineDocument struct {
	Id          bson.ObjectId `bson:"_id" json:"-"`
	Label       string        `bson:"label"`
	Domain      string        `bson:"domain"`
	QueryString string        `bson:"queryString"`
	IpAddress   string        `bson:"ipAddress"`
	Assignee    struct {
		InProgress bool      `bson:"inProgress"`
		AssignedAt time.Time `bson:"assignedAt"`
	} `bson:"assignee"`
	Status struct {
		State      string    `bson:"state"`
		Reason     string    `bson:"reason"`
		ModifiedAt time.Time `bson:"modifiedAt"`
	} `bson:"status"`
	Provider   string               `bson:"provider"`
	Credential string               `bson:"credential"`
	CreatedAt  time.Time            `bson:"createdAt"`
	Meta       bson.M               `bson:"meta"`
	Users      []models.Permissions `bson:"users"`
	Groups     []models.Permissions `bson:"groups"`
}

type mongodbInstances struct {
	DB *mongodb.MongoDB
}

func NewMongoDB(url string) *mongodbInstances {
	return &mongodbInstances{
		DB: mongodb.NewMongoDB(url),
	}
}

// Iter iterates over all machine documents and executes fn for each new
// iteration.
func (m *mongodbInstances) Iter(fn func(MachineDocument) error) error {
	query := func(c *mgo.Collection) error {
		machinesWithIds := bson.M{
			"meta.instanceId": bson.M{"$exists": true, "$ne": ""},
		}

		machine := MachineDocument{}
		iter := c.Find(machinesWithIds).Batch(150).Iter()
		for iter.Next(&machine) {
			if err := fn(machine); err != nil {
				fmt.Printf("iter err: %s\n", err)
			}
		}

		return iter.Close()
	}

	return m.DB.Run("jMachines", query)
}
