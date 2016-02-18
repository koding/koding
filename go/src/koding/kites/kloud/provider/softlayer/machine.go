package softlayer

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"
	"strings"
	"time"

	"golang.org/x/net/context"

	"koding/kites/kloud/contexthelper/session"

	"github.com/koding/logging"
	"github.com/maximilien/softlayer-go/softlayer"
	"github.com/mitchellh/mapstructure"
)

type Meta struct {
	Id          int    `bson:id`
	AlwaysOn    bool   `bson:"alwaysOn"`
	Datacenter  string `structs:"datacenter" bson:"datacenter"`
	SourceImage string `structs:"sourceImage" bson:"sourceImage"`
	VlanID      int    `structs:"vlanId" bson:"vlanId"`
}

// Machine represents a single MongodDB document from the jMachines collection.
type Machine struct {
	*models.Machine

	// internal fields, not availabile in MongoDB schema
	Username string                 `bson:"-"`
	User     *models.User           `bson:"-"`
	Payment  *plans.PaymentResponse `bson:"-"`
	Checker  plans.Checker          `bson:"-"`
	Session  *session.Session       `bson:"-"`
	Log      logging.Logger         `bson:"-"`

	// timeouts
	KlientTimeout time.Duration `bson:"-"`
	StateTimeout  time.Duration `bson:"-"`
}

func (m *Machine) GetMeta() (*Meta, error) {
	var mt Meta
	if err := mapstructure.Decode(m.Meta, &mt); err != nil {
		return nil, err
	}

	return &mt, nil
}

func (m *Machine) ProviderName() string { return m.Provider }

func (m *Machine) IsKlientReady() bool {
	m.Log.Debug("All finished, testing for klient connection IP [%s]", m.IpAddress)
	klientRef, err := klient.NewWithTimeout(m.Session.Kite, m.QueryString, m.KlientTimeout)
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

type transitionFunc func(context.Context) error

func (m *Machine) guardTransition(start machinestate.State, reason string, ctx context.Context, fn transitionFunc) error {
	err := modelhelper.ChangeMachineState(m.ObjectId, reason, start)
	if err != nil {
		return err
	}

	latest := m.State()
	err = fn(ctx)
	if err != nil {
		e := modelhelper.ChangeMachineState(m.ObjectId, "Machine is marked as "+latest.String(), latest)
		if e != nil {
			m.Log.Warning("failure reverting state from %q to %q: %s", start, latest, e)
		}

		return err
	}

	return nil
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

func (m *Machine) waitState(sl softlayer.SoftLayer_Virtual_Guest_Service, id int, state string, timeout time.Duration) error {
	t := time.After(timeout)
	ticker := time.NewTicker(time.Second * 20)
	defer ticker.Stop()

	want := strings.ToLower(strings.TrimSpace(state))

	for {
		select {
		case <-ticker.C:
			s, err := sl.GetPowerState(id)
			if err != nil {
				return err
			}

			got := strings.ToLower(strings.TrimSpace(s.KeyName))

			m.Log.Debug("[%d] got state %q, want %q", id, got, want)

			if got == want {
				return nil
			}
		case <-t:
			return errors.New("timeout while waiting for state")
		}
	}

}

func (m *Machine) MarkAsStoppedWithReason(reason string) error {
	m.Log.Debug("Marking instance as stopped")
	if err := modelhelper.ChangeMachineState(m.ObjectId, reason, machinestate.Stopped); err != nil {
		return err
	}

	// so any State() method returns the correct status
	m.Status.State = machinestate.Stopped.String()
	return nil
}
