package newkoding

import (
	"koding/db/models"
	"koding/kites/kloud/machinestate"
	"time"

	"github.com/koding/logging"

	"labix.org/v2/mgo/bson"
)

// Machine represents a single MongodDB document from the jMachines
// collection.
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
	Provider   string    `bson:"provider"`
	Credential string    `bson:"credential"`
	CreatedAt  time.Time `bson:"createdAt"`
	Meta       struct {
		AlwaysOn     bool   `bson:"alwaysOn"`
		InstanceId   string `bson:"instanceId"`
		InstanceType string `bson:"instance_type"`
		InstanceName string `bson:"instanceName"`
		Region       string `bson:"region"`
		StorageSize  int    `bson:"storage_size"`
		SourceAmi    string `bson:"source_ami"`
	} `bson:"meta"`
	Users  []models.Permissions `bson:"users"`
	Groups []models.Permissions `bson:"groups"`

	// not availabile in MongoDB schema
	Username string `bson:"-"`
	Log      logging.Logger
}

func (m *Machine) State() machinestate.State {
	return machinestate.States[m.Status.State]
}

type Credential struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	PublicKey string        `bson:"publicKey"`
	Meta      bson.M        `bson:"meta"`
}
