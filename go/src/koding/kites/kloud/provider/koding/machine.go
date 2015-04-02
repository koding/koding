package koding

import (
	"koding/db/models"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"
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
		InstanceId   string `structs:"instanceId" bson:"instanceId"`
		InstanceType string `structs:"instance_type" bson:"instance_type"`
		InstanceName string `structs:"instanceName" bson:"instanceName"`
		Region       string `structs:"region" bson:"region"`
		StorageSize  int    `structs:"storage_size" bson:"storage_size"`
		SourceAmi    string `structs:"source_ami" bson:"source_ami"`
		SnapshotId   string `structs:"snapshotId" bson:"-"`
	} `bson:"meta"`
	Users  []models.Permissions `bson:"users"`
	Groups []models.Permissions `bson:"groups"`

	// internal fields, not availabile in MongoDB schema
	Username string                 `bson:"-"`
	User     *models.User           `bson:"-"`
	Payment  *plans.PaymentResponse `bson:"-"`
	Checker  plans.Checker          `bson:"-"`
	Session  *session.Session       `bson:"-"`
	Log      logging.Logger         `bson:"-"`

	// cleanFuncs are a list of functions that are called when after a method
	// is finished
	cleanFuncs []func()
}

// runCleanupFunctions calls all cleanup functions and set the
// list to nil. Once called any other call will not have any
// effect.
func (m *Machine) runCleanupFunctions() {
	if m.cleanFuncs == nil {
		return
	}

	for _, fn := range m.cleanFuncs {
		fn()
	}

	m.cleanFuncs = nil
}

func (m *Machine) State() machinestate.State {
	return machinestate.States[m.Status.State]
}

func (m *Machine) PublicIpAddress() string {
	return m.IpAddress
}

// push pushes the given message to the eventer
func (m *Machine) push(msg string, percentage int, state machinestate.State) {
	if m.Session.Eventer != nil {
		m.Session.Eventer.Push(&eventer.Event{
			Message:    msg,
			Percentage: percentage,
			Status:     state,
		})
	}
}
