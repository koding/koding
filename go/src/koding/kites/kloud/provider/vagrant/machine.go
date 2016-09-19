package vagrant

import (
	"errors"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/provider"
)

type Meta struct {
	AlwaysOn       bool   `bson:"alwaysOn"`
	StorageSize    int    `bson:"storage_size"`
	FilePath       string `bson:"filePath"`
	Memory         int    `bson:"memory"`
	CPU            int    `bson:"cpus"`
	Hostname       string `bson:"hostname"`
	KlientHostURL  string `bson:"klientHostURL"`
	KlientGuestURL string `bson:"klientGuestURL"`
}

func (meta *Meta) Valid() error {
	if meta.FilePath == "" {
		return errors.New("vagrant's FilePath metadata is empty")
	}

	return nil
}

type Machine struct {
	*provider.BaseMachine

	Meta    *Meta              `bson:"-"`
	Cred    *Cred              `bson:"-"`
	Vagrant *vagrantapi.Klient `bson:"-"`
}

func (m *Machine) updateState(s machinestate.State) error {
	return modelhelper.ChangeMachineState(m.ObjectId, "Machine is marked as "+s.String(), s)
}
