package generic

import (
	"koding/db/models"
	"koding/kites/kloud/machinestate"
	"time"

	"labix.org/v2/mgo/bson"
)

// Machine represents a single MongoDB document from the jMachine collection.
// Any Provider is satisfied.
type Machine struct {
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

func (m *Machine) State() machinestate.State {
	return machinestate.States[m.Status.State]
}

func (m *Machine) PublicIpAddress() string {
	return m.IpAddress
}
