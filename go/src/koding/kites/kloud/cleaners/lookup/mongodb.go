package lookup

import (
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
func (m *MongoDB) Iter(fn func(MachineDocument)) error {
	query := func(c *mgo.Collection) error {
		machinesWithIds := bson.M{
			"meta.instanceId": bson.M{"$exists": true, "$ne": ""},
		}

		machine := MachineDocument{}
		iter := c.Find(machinesWithIds).Batch(150).Iter()
		for iter.Next(&machine) {
			fn(machine)
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
			"provider":      "koding",
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

// Machines returns a list of machines for the given instanceIds
func (m *MongoDB) Machines(instanceIds ...string) ([]MachineDocument, error) {
	machines := make([]MachineDocument, 0)

	query := func(c *mgo.Collection) error {
		all := bson.M{
			"meta.instanceId": bson.M{"$in": instanceIds},
		}

		machine := MachineDocument{}
		iter := c.Find(all).Batch(150).Iter()
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
	users, err := m.Users(usernames...)
	if err != nil {
		return err
	}

	userIds := make([]bson.ObjectId, len(users))
	for i, user := range users {
		userIds[i] = user.ObjectId
	}

	query := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(
			bson.M{
				"provider":    "koding",
				"users.id":    bson.M{"$in": userIds},
				"users.sudo":  true,
				"users.owner": true,
			},
			bson.M{"$set": bson.M{"meta.alwaysOn": false}},
		)

		return err
	}

	return m.DB.Run("jMachines", query)
}

func (m *MongoDB) Users(usernames ...string) ([]models.User, error) {
	users := make([]models.User, 0)

	query := func(c *mgo.Collection) error {
		all := bson.M{
			"username": bson.M{"$in": usernames},
		}

		user := models.User{}
		iter := c.Find(all).Batch(150).Iter()
		for iter.Next(&user) {
			users = append(users, user)
		}

		return iter.Close()
	}

	if err := m.DB.Run("jUsers", query); err != nil {
		return nil, err
	}

	return users, nil
}

func (m *MongoDB) NotConfirmedUsers() ([]models.User, error) {
	users := make([]models.User, 0)

	query := func(c *mgo.Collection) error {
		notConfirmed := bson.M{
			"status": bson.M{"$exists": true, "$ne": "confirmed"},
		}

		user := models.User{}
		iter := c.Find(notConfirmed).Batch(150).Iter()
		for iter.Next(&user) {
			users = append(users, user)
		}

		return iter.Close()
	}

	if err := m.DB.Run("jUsers", query); err != nil {
		return nil, err
	}

	return users, nil
}
