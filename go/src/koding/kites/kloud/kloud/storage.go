package kloud

import (
	"fmt"
	"koding/db/mongodb"
	"koding/kites/kloud/kloud/machinestate"
	"time"

	"github.com/koding/logging"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type StorageData struct {
	Type string
	Data map[string]interface{}
}

type Storage interface {
	// Get returns to MachineData
	Get(string, *GetOption) (*MachineData, error)

	// Update updates the fields in the data for the given id
	Update(string, *StorageData) error

	// UpdateState updates the machine state for the given machine id
	UpdateState(string, machinestate.State) error

	// ResetAssignee resets the assigne which was acquired with Get()
	ResetAssignee(id string) error

	// Assignee returns the unique identifier that is responsible of doing the
	// actions of this interface.
	Assignee() string
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
	session  *mongodb.MongoDB
	assignee string
	log      logging.Logger
}

// Assignee returns the assignee responsible for MongoDB actions, in our case
// it's the Kloud name together with hostname and a unique identifier.
func (m *MongoDB) Assignee() string { return m.assignee }

// Get returns the meta of the associated credential with the given machine id.
func (m *MongoDB) Get(id string, opt *GetOption) (*MachineData, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Invalid machine id: %q", id)
	}

	// let's first check if the id exists, because we are going to use
	// findAndModify() and it would be difficult to distinguish if the id
	// really doesn't exist or if there is an assignee which is a different
	// thing. (Because findAndModify() also returns "not found" for the case
	// where the id exist but someone else is the assignee).
	if err := m.session.Run("jMachines", func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(nil)
	}); err == mgo.ErrNotFound {
		return nil, NewError(ErrMachineNotFound)
	}

	// we use findAndModify() to get a unique lock from the DB. That means only
	// one instance should be responsible for this action. We will update the
	// assignee if none else is doing stuff with it.
	change := mgo.Change{
		Update: bson.M{
			"$set": bson.M{
				"assignee.name": m.Assignee(),
				"assignee.time": time.Now(),
			},
		},
		ReturnNew: true,
	}

	machine := &Machine{}
	if opt.IncludeMachine {
		err := m.session.Run("jMachines", func(c *mgo.Collection) error {
			// If Find() is successful the Update() above will be applied
			// (which set's us as assignee). If not, it means someone else is
			// working on this document and we should return with an error. The
			// whole process is Atomic and a single transaction.

			// Now we query for our document. There are two cases:

			// 1.) assigne.name is nil: A nil assignee means that nobody has
			// picked it up yet and we are good to go.

			// 2.) assigne.name is not nil: kloud might crash during the time
			// it has selected the document but couldn't unset assigne.name to
			// nil. If kloud doesn't start (because it cleans documents that
			// belongs to himself at start), assigne.name will be always
			// non-nil. If that instance nevers starts assigne will not changed
			// ever.

			// Therefore we are going to check if it was assigned 10 minutes
			// ago and reassign again. However, we also add an additional check
			// which will prevent multiple readers update the same document. If
			// one is able to query the document the Update() above will update
			// the assignedAt to current date, but the next one will be not
			// able to query it because the second additional date is not valid
			// anymore.
			_, err := c.Find(
				bson.M{
					"_id": bson.ObjectIdHex(id),
					"$or": []bson.M{
						bson.M{"assignee.name": nil},
						bson.M{"$and": []bson.M{
							bson.M{"assignee.assignedAt": bson.M{"$lt": time.Now().Add(time.Minute * 10)}},
							bson.M{"assignee.assignedAt": bson.M{"$lt": time.Now().Add(-time.Second * 30)}},
						}},
					},
				}).Apply(change, &machine)
			return err
		})

		// query didn't matched, means it's assigned to some other Kloud
		// instances and an ongoing event is in process.
		if err == mgo.ErrNotFound {
			return nil, NewError(ErrMachinePendingEvent)
		}

		// some other error, this shouldn't be happed
		if err != nil {
			m.log.Error("Storage get error: %s", err.Error())
			return nil, NewError(ErrBadState)
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

func (m *MongoDB) Update(id string, s *StorageData) error {
	m.log.Debug("[storage] got update request for id '%s' of type '%s'", id, s.Type)

	if s.Type == "build" {
		return m.session.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				bson.ObjectIdHex(id),
				bson.M{"$set": bson.M{
					"queryString":       s.Data["queryString"],
					"ipAddress":         s.Data["ipAddress"],
					"meta.instanceId":   s.Data["instanceId"],
					"meta.instanceName": s.Data["instanceName"],
				}},
			)
		})
	}

	if s.Type == "info" {
		return m.session.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				bson.ObjectIdHex(id),
				bson.M{"$set": bson.M{
					"meta.instanceName": s.Data["instanceName"],
				}},
			)
		})
	}

	return fmt.Errorf("Storage type unknown: '%s'", s.Type)
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

// ResetAssignee resets the assigne for the given id to nil.
func (m *MongoDB) ResetAssignee(id string) error {
	return m.session.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": bson.M{"assignee.name": nil}},
		)
	})
}

// CleanupOldData cleans up the assigne name that was bound to this kloud but
// didn't get unset. This happens when the kloud instance crashes before it
// could unset the assigne.name
func (m *MongoDB) CleanupOldData() error {
	return m.session.Run("jMachines", func(c *mgo.Collection) error {
		_, err := c.UpdateAll(
			bson.M{"assignee.name": m.Assignee()},
			bson.M{"$set": bson.M{"assignee.name": nil}},
		)
		return err
	})
}
