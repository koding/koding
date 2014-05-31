package kloud

import (
	"fmt"
	"koding/db/mongodb"
	"koding/kites/kloud/kloud/protocol"
	"strconv"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Storage interface {
	// Get returns to MachineData
	Get(string) (*MachineData, error)

	// Update updates the fields in the data for the given id
	Update(string, *protocol.BuildResponse) error

	// UpdateState updates the machine state
	UpdateState(string, MachineState) error

	// GetState returns the machine state
	GetState(string) (MachineState, error)
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

// Get returns the meta of the associated credential with the given machine id.
func (m *MongoDB) Get(id string) (*MachineData, error) {
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

func (m *MongoDB) Update(id string, resp *protocol.BuildResponse) error {
	err := m.session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": bson.M{
				"kiteId":            resp.KiteId,
				"ipAddress":         resp.IpAddress,
				"state":             "READY",
				"meta.instanceId":   strconv.Itoa(resp.InstanceId),
				"meta.instanceName": resp.InstanceName,
			}},
		)
	})
	if err != nil {
		return err
	}

	return nil
}

func (m *MongoDB) UpdateState(id string, state MachineState) error {
	return m.session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": bson.M{"state": state.String()}},
		)
	})
}

func (m *MongoDB) GetState(id string) (MachineState, error) {
	machine := Machine{}
	err := m.session.Run("jMachines", func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&machine)
	})
	if err != nil {
		return 0, err
	}

	state := states[machine.State]
	if state == 0 {
		return 0, fmt.Errorf("state is unknown: %v", state)
	}

	return state, nil
}
