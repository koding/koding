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

type MongoDB struct {
	DB *mongodb.MongoDB
}

func NewMongoDB(url string) *MongoDB {
	return &MongoDB{
		DB: mongodb.NewMongoDB(url),
	}
}

// Iter iterates over all machine documents and executes fn for each new
// iteration.
func (m *MongoDB) Iter(fn func(MachineDocument) error) error {
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

// AlwaysOn returns all alwaysOn Machines
func (m *MongoDB) AlwaysOn() ([]MachineDocument, error) {
	machines := make([]MachineDocument, 0)

	query := func(c *mgo.Collection) error {
		alwaysOn := bson.M{
			"meta.alwaysOn": true,
		}

		machine := MachineDocument{}
		iter := c.Find(alwaysOn).Batch(150).Iter()
		for iter.Next(&machine) {
			machines = append(machines, machine)
		}

		return iter.Close()
	}

	if err := m.DB.Run("jMachines", query); err != nil {
		return nil, err
	}

	return machines, nil
}

// Accounts returns a list of accounts for the give objectIds in non hex form
func (m *MongoDB) Accounts(ids ...string) ([]models.Account, error) {
	b := make([]bson.ObjectId, len(ids))
	for i, id := range ids {
		b[i] = bson.ObjectIdHex(id)
	}

	accounts := make([]models.Account, 0)

	query := func(c *mgo.Collection) error {
		all := bson.M{
			"_id": bson.M{"$in": b},
		}

		account := models.Account{}
		iter := c.Find(all).Batch(150).Iter()
		for iter.Next(&account) {
			accounts = append(accounts, account)
		}

		return iter.Close()
	}

	if err := m.DB.Run("jAccounts", query); err != nil {
		return nil, err
	}

	return accounts, nil
}

// RemoveAlwaysOn removes the alwaysOn flag for the given usernames
func (m *MongoDB) RemoveAlwaysOn(usernames ...string) error {
	query := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(
			bson.M{"credential": bson.M{"$in": usernames}},
			bson.M{"$set": bson.M{"meta.alwaysOn": false}},
		)

		return err
	}

	return m.DB.Run("jMachines", query)
}
