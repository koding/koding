package kloud

import (
	"koding/db/mongodb"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Storage interface {
	Add(map[string]interface{}) error

	// MachineData returns to MachineData
	MachineData(id string) (*MachineData, error)
}

type MachineData struct {
	Provider   string
	Credential map[string]interface{}
	Builders   map[string]interface{}
}

type Machine struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	KiteId     string        `bson:"kiteId"`
	PublicIp   string        `bson:"publicIp"`
	State      string        `bson:"state"`
	Provider   string        `bson:"provider"`
	Credential string        `bson:"credential"`
	Meta       bson.M        `bson:"meta"`
}

type CredentialData struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	PublicKey string        `bson:"publicKey"`
	Meta      bson.M        `bson:"meta"`
}

type MongoDB struct {
	session *mongodb.MongoDB
}

// MachineData returns the meta of the associated credential with the given machine id.
func (m *MongoDB) MachineData(id string) (*MachineData, error) {
	machine := Machine{}
	err := m.session.Run("jMachines", func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&machine)
	})
	if err != nil {
		return nil, err
	}

	credentialData := CredentialData{}
	err = m.session.Run("jCredentialDatas", func(c *mgo.Collection) error {
		return c.Find(bson.M{"publicKey": machine.Credential}).One(&credentialData)
	})
	if err != nil {
		return nil, err
	}

	return &MachineData{
		Provider:   machine.Provider,
		Credential: credentialData.Meta,
		Builders:   machine.Meta,
	}, nil
}

func (m *MongoDB) Add(data map[string]interface{}) error {
	// response := &BuildResponse{}
	// if err := mapstructure.Decode(data, response); err != nil {
	// 	return err
	// }

	return nil
}
