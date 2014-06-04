package kloud

import (
	"koding/db/mongodb"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"strconv"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Storage interface {
	// Get returns to MachineData
	Get(string, *GetOption) (*MachineData, error)

	// Update updates the fields in the data for the given id
	Update(string, *protocol.BuildResponse) error

	// GetState returns the machine state for the given machine id
	GetState(id string) (machinestate.State, error)

	// UpdateState updates the machine state for the given machine id
	UpdateState(string, machinestate.State) error
}

// GetOption defines which parts should be included into MachineData, used for
// optimizing the the performance for certain lookups.
type GetOption struct {
	IncludeMachine    bool
	IncludeCredential bool
}

type MachineData struct {
	Provider   string
	Machine    *Machine
	Credential *Credential
}

type Credential struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	PublicKey string        `bson:"publicKey"`
	Meta      bson.M        `bson:"meta"`
}

type MongoDB struct {
	session *mongodb.MongoDB
}

// Get returns the meta of the associated credential with the given machine id.
func (m *MongoDB) Get(id string, opt *GetOption) (*MachineData, error) {
	machine := &Machine{}

	if opt.IncludeMachine {
		err := m.session.Run("jMachines", func(c *mgo.Collection) error {
			return c.FindId(bson.ObjectIdHex(id)).One(machine)
		})
		if err != nil {
			return nil, err
		}
	}

	credential := &Credential{}
	if opt.IncludeCredential {
		// we neglect errors because credential is optional
		m.session.Run("jCredentialDatas", func(c *mgo.Collection) error {
			return c.Find(bson.M{"publicKey": machine.Credential}).One(credential)
		})
	}

	return &MachineData{
		Provider:   machine.Provider,
		Credential: credential,
		Machine:    machine,
	}, nil
}

func (m *MongoDB) Update(id string, resp *protocol.BuildResponse) error {
	err := m.session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": bson.M{
				"queryString":       resp.QueryString,
				"publicIp":          resp.IpAddress,
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

func (m *MongoDB) GetState(id string) (machinestate.State, error) {
	machine, err := m.Get(id, &GetOption{IncludeMachine: true})
	if err != nil {
		return 0, err
	}

	return machine.Machine.State(), nil
}

func (m *MongoDB) UpdateState(id string, state machinestate.State) error {
	return m.session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now(),
				},
			},
		)
	})
}
