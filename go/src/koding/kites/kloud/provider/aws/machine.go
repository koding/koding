package awsprovider

import (
	"koding/db/models"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"
	"time"

	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Meta struct {
	AlwaysOn     bool   `bson:"alwaysOn"`
	InstanceId   string `structs:"instanceId" bson:"instanceId"`
	InstanceType string `structs:"instance_type" bson:"instance_type"`
	InstanceName string `structs:"instanceName" bson:"instanceName"`
	Region       string `structs:"region" bson:"region"`
	StorageSize  int    `structs:"storage_size" bson:"storage_size"`
	SourceAmi    string `structs:"source_ami" bson:"source_ami"`
	SnapshotId   string `structs:"snapshotId" bson:"-"`
}

// Machine represents a single MongodDB document from the jMachines
// collection.
type Machine struct {
	*models.Machine

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

func (m *Machine) GetMeta() (*Meta, error) {
	var mt Meta
	if err := mapstructure.Decode(m.Meta, &mt); err != nil {
		return nil, err
	}

	return &mt, nil
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

func (m *Machine) IsKlientReady() bool {
	m.Log.Debug("All finished, testing for klient connection IP [%s]", m.IpAddress)
	klientRef, err := klient.NewWithTimeout(m.Session.Kite, m.QueryString, time.Minute*5)
	if err != nil {
		m.Log.Warning("Connecting to remote Klient instance err: %s", err)
		return false
	}
	defer klientRef.Close()

	m.Log.Debug("Sending a ping message")
	if err := klientRef.Ping(); err != nil {
		m.Log.Debug("Sending a ping message err: %s", err)
		return false
	}

	return true
}

// markAsNotInitialized marks the machine as NotInitialized by cleaning up all
// necessary fields and marking the VM as notinitialized so the User can build
// it again.
func (m *Machine) MarkAsNotInitialized() error {
	m.Log.Warning("Instance is not available. Marking it as NotInitialized")
	if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":          "",
				"queryString":        "",
				"meta.instance_type": "",
				"meta.instanceName":  "",
				"meta.instanceId":    "",
				"status.state":       machinestate.NotInitialized.String(),
				"status.modifiedAt":  time.Now().UTC(),
				"status.reason":      "Machine is marked as NotInitialized",
			}},
		)
	}); err != nil {
		return err
	}

	m.IpAddress = ""
	m.QueryString = ""
	m.Meta["instance_type"] = ""
	m.Meta["instanceName"] = ""
	m.Meta["instanceId"] = ""

	// so any State() method can return the correct status
	m.Status.State = machinestate.NotInitialized.String()
	return nil
}

func (m *Machine) ProviderName() string { return m.Provider }
