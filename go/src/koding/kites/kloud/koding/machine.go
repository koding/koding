package koding

import (
	"koding/db/models"
	"time"

	"koding/kites/kloud/machinestate"

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
		ModifiedAt time.Time `bson:"modifiedAt"`
	} `bson:"status"`
	Provider   string               `bson:"provider"`
	Credential string               `bson:"credential"`
	CreatedAt  time.Time            `bson:"createdAt"`
	Meta       bson.M               `bson:"meta"`
	Users      []models.Permissions `bson:"users"`
	Groups     []models.Permissions `bson:"groups"`
}

func (m *MachineDocument) State() machinestate.State {
	return machinestate.States[m.Status.State]
}

type Credential struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	PublicKey string        `bson:"publicKey"`
	Meta      bson.M        `bson:"meta"`
}
