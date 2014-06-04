package kloud

import (
	"koding/kites/kloud/kloud/machinestate"
	"time"

	"labix.org/v2/mgo/bson"
)

type Machine struct {
	Id          bson.ObjectId `bson:"_id" json:"-"`
	QueryString string        `bson:"queryString"`
	PublicIp    string        `bson:"publicIp"`
	Status      struct {
		State      string    `bson:"state"`
		ModifiedAt time.Time `bson:"modifiedAt"`
	} `bson:"status"`
	Provider   string    `bson:"provider"`
	Credential string    `bson:"credential"`
	CreatedAt  time.Time `json:"createdAt"`
	Meta       bson.M    `bson:"meta"`
}

func (m *Machine) State() machinestate.State {
	return machinestate.States[m.Status.State]
}
