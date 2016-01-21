package vagrant

import (
	"errors"
	"koding/db/models"

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

// Machine
type Machine struct {
	*models.Machine
}

// GetMeta
func (m *Machine) GetMeta() (*Meta, error) {
	var mt Meta
	if err := mapstructure.Decode(m.Meta, &mt); err != nil {
		return nil, err
	}

	return &mt, nil
}
