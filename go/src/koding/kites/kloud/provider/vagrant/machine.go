package vagrant

import (
	"errors"
	"time"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"

	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"
)

type Meta struct {
	AlwaysOn        bool   `bson:"alwaysOn"`
	StorageSize     int    `bson:"storage_size"`
	FilePath        string `bson:"filePath"`
	HostQueryString string `bson:"hostQueryString"`
	Memory          int    `bson:"memory"`
	CPU             int    `bson:"cpus"`
	Hostname        string `bson:"hostname"`
	KlientHostURL   string `bson:"klientHostURL"`
	KlientGuestURL  string `bson:"klientGuestURL"`
}

func (meta *Meta) Valid() error {
	if meta.FilePath == "" {
		return errors.New("vagrant's FilePath metadata is empty")
	}
	if meta.HostQueryString == "" {
		return errors.New("vagrant's HostQueryString metadata is empty")
	}
	return nil
}

type Machine struct {
	*models.Machine

	Meta    *Meta            `bson:"-"`
	User    *models.User     `bson:"-"`
	Session *session.Session `bson:"-"`
	Log     logging.Logger   `bson:"-"`

	api *vagrantapi.Klient
}

func (m *Machine) GetMeta() (*Meta, error) {
	var mt Meta
	if err := mapstructure.Decode(m.Meta, &mt); err != nil {
		return nil, err
	}

	if err := mt.Valid(); err != nil {
		return nil, err
	}

	return &mt, nil
}

// State returns the machinestate of the machine.
func (m *Machine) State() machinestate.State {
	return machinestate.States[m.Status.State]
}

// push pushes the given message to the eventer
func (m *Machine) push(msg string, n int, s machinestate.State) {
	if m.Session.Eventer != nil {
		m.Session.Eventer.Push(&eventer.Event{
			Message:    msg,
			Percentage: n,
			Status:     s,
		})
	}
}

func (m *Machine) markAsNotInitialized() error {
	m.Log.Warning("Instance is not available. Marking it as NotInitialized")

	if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":           "",
				"queryString":         "",
				"meta.filePath":       "",
				"meta.klientGuestURL": "",
				"meta.cpu":            0,
				"meta.memory":         0,
				"status.state":        machinestate.NotInitialized.String(),
				"status.modifiedAt":   time.Now().UTC(),
				"status.reason":       "Machine is marked as NotInitialized",
			}},
		)
	}); err != nil {
		return err
	}

	m.IpAddress = ""
	m.QueryString = ""
	m.Machine.Meta["filePath"] = ""
	m.Machine.Meta["klientGuestURL"] = ""
	m.Machine.Meta["cpu"] = 0
	m.Machine.Meta["memory"] = 0

	// so any State() method can return the correct status
	m.Status.State = machinestate.NotInitialized.String()
	return nil
}

func (m *Machine) waitKlientReady() bool {
	m.Log.Debug("All finished, testing for klient connection IP [%s]", m.IpAddress)

	klientRef, err := klient.NewWithTimeout(m.Session.Kite, m.QueryString, time.Minute*5)
	if err != nil {
		m.Log.Warning("Connecting to remote Klient instance err: %s", err)
		return false
	}
	defer klientRef.Close()

	m.Log.Debug("Sending a ping message ot %q", m.QueryString)

	if err := klientRef.Ping(); err != nil {
		m.Log.Debug("Sending a ping message err: %s", err)
		return false
	}

	return true
}

func (m *Machine) updateState(s machinestate.State) error {
	return modelhelper.ChangeMachineState(m.ObjectId, "Machine is marked as "+s.String(), s)
}
