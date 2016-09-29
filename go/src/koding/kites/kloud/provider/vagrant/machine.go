package vagrant

import (
	"fmt"

	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

type Machine struct {
	*provider.BaseMachine
	api *vagrantapi.Klient `bson:"-"`
}

var (
	_ provider.Machine = (*Machine)(nil)
	_ stack.Machiner   = (*Machine)(nil)
)

func (m *Machine) Start(context.Context) (interface{}, error) {
	return nil, m.wrap(m.api.Up(m.Cred().QueryString, m.Meta().FilePath))
}

func (m *Machine) Stop(context.Context) (interface{}, error) {
	return nil, m.wrap(m.api.Halt(m.Cred().QueryString, m.Meta().FilePath))
}

func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	// List is used here to workaround vagrantutil problem,
	// which does not report missing box when queried with a non-existing
	// box name.
	//
	// TODO(rjeczalik): fix vagrantutil instead
	list, err := m.api.List(m.Cred().QueryString)
	if err == kite.ErrNoKitesAvailable || err == klient.ErrDialingFailed {
		return machinestate.Stopped, nil, nil
	}

	if err != nil {
		return 0, nil, err
	}

	for _, l := range list {
		if l.FilePath == m.Meta().FilePath {
			return l.State.MachineState(), nil, nil
		}
	}

	return machinestate.Terminated, nil, nil
}

func (m *Machine) wrap(err error) error {
	switch err {
	case kite.ErrNoKitesAvailable, klient.ErrDialingFailed:
		return fmt.Errorf(`Failure connecting to KD (%s). Please start it with "sudo kd start".`, m.Cred().QueryString)
	default:
		return err
	}
}

func (m *Machine) Cred() *Cred {
	return m.BaseMachine.Credential.(*Cred)
}

func (m *Machine) Meta() *Meta {
	return m.BaseMachine.Metadata.(*Meta)
}
