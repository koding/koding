package kloud

import (
	"time"

	"github.com/koding/kloud/machinestate"

	"labix.org/v2/mgo/bson"
)

type Machine struct {
	Id          bson.ObjectId `bson:"_id" json:"-"`
	QueryString string        `bson:"queryString"`
	IpAddress   string        `bson:"ipAddress"`
	Assignee    struct {
		Name       string    `bson:"name"`
		AssignedAt time.Time `bson:"assignedAt"`
	} `bson:"assignee"`
	Status struct {
		State      string    `bson:"state"`
		ModifiedAt time.Time `bson:"modifiedAt"`
	} `bson:"status"`
	Provider   string    `bson:"provider"`
	Credential string    `bson:"credential"`
	CreatedAt  time.Time `bson:"createdAt"`
	Meta       bson.M    `bson:"meta"`
}

func (m *Machine) State() machinestate.State {
	return machinestate.States[m.Status.State]
}
