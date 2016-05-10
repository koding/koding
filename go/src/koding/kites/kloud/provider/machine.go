package provider

import (
	"fmt"
	"time"

	"koding/db/models"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"

	"github.com/koding/kite"
)

var DefaultKlientTimeout = 5 * time.Minute

type BaseMachine struct {
	*models.Machine
	*session.Session `bson:"-"`

	// Fields set by (*Provider).BaseMachine
	Provider string        `bson:"-"`
	TraceID  string        `bson:"-"`
	Debug    bool          `bson:"-"`
	User     *models.User  `bson:"-"`
	Req      *kite.Request `bson:"-"`

	// Fields configured by concrete provider.
	KlientTimeout time.Duration `bson:"-"`
}

func (bm *BaseMachine) ProviderName() string {
	return bm.Provider
}

// Username gives name of user that owns the machine or requested an
// action on the machine.
func (bm *BaseMachine) Username() string {
	if bm.User != nil {
		return bm.User.Name
	}

	return bm.Req.Username
}

// State returns the machinestate of the machine.
func (bm *BaseMachine) State() machinestate.State {
	return machinestate.States[bm.Status.State]
}

func (bm *BaseMachine) WaitKlientReady() error {
	bm.Log.Debug("testing for %s (%s) klient kite connection", bm.QueryString, bm.IpAddress)

	c, err := klient.NewWithTimeout(bm.Kite, bm.QueryString, bm.klientTimeout())
	if err != nil {
		return fmt.Errorf("connection test for %s (%s) klient error: %s", bm.QueryString, bm.IpAddress, err)
	}
	defer c.Close()

	if err := c.Ping(); err != nil {
		return fmt.Errorf("pinging %s (%s) klient error: %s", bm.QueryString, bm.IpAddress, err)
	}

	return nil
}

func (bm *BaseMachine) PushEvent(msg string, percentage int, state machinestate.State) {
	if bm.Eventer != nil {
		bm.Eventer.Push(&eventer.Event{
			Message:    msg,
			Percentage: percentage,
			Status:     state,
		})
	}
}

func (bm *BaseMachine) klientTimeout() time.Duration {
	if bm.KlientTimeout != 0 {
		return bm.KlientTimeout
	}

	return DefaultKlientTimeout
}
