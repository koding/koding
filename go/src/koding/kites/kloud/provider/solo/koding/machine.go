package koding

import (
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"
	"koding/kites/kloud/stack"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var (
	// DefaultKlientTimeout is the max duration of time we try to connect
	// to a Klient to ensure it's running.

	DefaultKlientTimeout = 5 * time.Minute

	// T2Nano is the same as above with the only difference it applies to
	// t2.nano instances only.
	T2NanoKlientTimeout = 8 * time.Minute
)

type Meta struct {
	AlwaysOn     bool   `bson:"alwaysOn"`
	InstanceId   string `structs:"instanceId" bson:"instanceId"`
	InstanceType string `structs:"instance_type" bson:"instance_type"`
	InstanceName string `structs:"instanceName" bson:"instanceName"`
	Region       string `structs:"region" bson:"region"`
	StorageSize  int    `structs:"storage_size" bson:"storage_size"`
	SourceAmi    string `structs:"source_ami" bson:"source_ami"`
	SnapshotId   string `structs:"snapshotId" bson:"snapshotId"`
}

// Machine represents a single MongodDB document that represents a Koding
// Provider from the jMachines collection.
type Machine struct {
	*models.Machine

	// internal fields, not availabile in MongoDB schema
	Username string                 `bson:"-"`
	User     *models.User           `bson:"-"`
	Payment  *plans.PaymentResponse `bson:"-"`
	Checker  plans.Checker          `bson:"-"`
	Session  *session.Session       `bson:"-"`
	Log      logging.Logger         `bson:"-"`
	Locker   stack.Locker           `bson:"-"`

	// cleanFuncs are a list of functions that are called when after a method
	// is finished
	cleanFuncs []func()
}

// NewMachine gives new Machine value.
func NewMachine() *Machine {
	return &Machine{
		Machine: &models.Machine{},
	}
}

func (m *Machine) GetMeta() (*Meta, error) {
	var mt Meta
	dec, err := mapstructure.NewDecoder(&mapstructure.DecoderConfig{
		TagName: "structs",
		Result:  &mt,
	})
	if err != nil {
		return nil, err
	}

	if err := dec.Decode(m.Meta); err != nil {
		return nil, err
	}

	return &mt, nil
}

// runCleanupFunctions calls all cleanup functions and set the
// list to nil. Once called any other call will not have any
// effect.
func (m *Machine) runCleanupFunctions() {
	if m.cleanFuncs == nil {
		return
	}

	for _, fn := range m.cleanFuncs {
		fn()
	}

	m.cleanFuncs = nil
}

func (m *Machine) PublicIpAddress() string {
	return m.IpAddress
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

// switchAWSRegion switches to the given AWS region. This should be only used when
// you know what to do, otherwiese never, never change the region of a machine.
func (m *Machine) switchAWSRegion(region string) error {
	m.Meta["instanceId"] = "" // we neglect any previous instanceId
	m.Meta["region"] = "us-east-1"
	m.QueryString = ""

	client, err := m.Session.AWSClients.Region("us-east-1")
	if err != nil {
		return err
	}
	m.Session.AWSClient.Client = client

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"meta.instanceId": "",
				"queryString":     "",
				"meta.region":     "us-east-1",
			}},
		)
	})
}

// markAsNotInitialized marks the machine as NotInitialized by cleaning up all
// necessary fields and marking the VM as notinitialized so the User can build
// it again.
func (m *Machine) markAsNotInitialized() error {
	m.Log.Warning("Instance is not available. Marking it as NotInitialized")
	if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":          "",
				"queryString":        "",
				"meta.instance_type": "",
				"meta.instanceName":  "",
				"meta.instanceId":    "",
				"status.state":       machinestate.NotInitialized.String(),
				"status.modifiedAt":  time.Now().UTC(),
				"status.reason":      "Machine is marked as NotInitialized",
			}},
		)
	}); err != nil {
		return err
	}

	m.IpAddress = ""
	m.QueryString = ""
	m.Meta["instance_type"] = ""
	m.Meta["instanceName"] = ""
	m.Meta["instanceId"] = ""

	// so any State() method can return the correct status
	m.Status.State = machinestate.NotInitialized.String()
	return nil
}

func (m *Machine) markAsStopped() error {
	return m.MarkAsStoppedWithReason("Machine is stopped")
}

func (m *Machine) MarkAsStoppedWithReason(reason string) error {
	m.Log.Debug("Marking instance as stopped")
	if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"status.state":      machinestate.Stopped.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     reason,
			}},
		)
	}); err != nil {
		return err
	}

	// so any State() method returns the correct status
	m.Status.State = machinestate.Stopped.String()
	return nil
}

func (m *Machine) updateStorageSize(size int) error {
	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{"meta.storage_size": size}},
		)
	})
}

func (m *Machine) klientTimeout() time.Duration {
	instanceType, ok := m.Meta["instance_type"].(string)

	// If instance type does not exist in meta we assume
	// it's t2.nano.
	if !ok || instanceType == plans.T2Nano.String() {
		return T2NanoKlientTimeout
	}

	return DefaultKlientTimeout
}

func (m *Machine) isKlientReady() bool {
	m.Log.Debug("All finished, testing for klient connection IP [%s]", m.IpAddress)
	klientRef, err := klient.NewWithTimeout(m.Session.Kite, m.QueryString, m.klientTimeout())
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

// Lock performs a Lock on this Machine
func (m *Machine) Lock() error {
	if !m.ObjectId.Valid() {
		return stack.NewError(stack.ErrMachineIdMissing)
	}

	if m.Locker == nil {
		return fmt.Errorf("Machine '%s' missing Locker", m.ObjectId.Hex())
	}

	return m.Locker.Lock(m.ObjectId.Hex())
}

// Unlock performs an Unlock on this Machine instance
func (m *Machine) Unlock() error {
	if !m.ObjectId.Valid() {
		return stack.NewError(stack.ErrMachineIdMissing)
	}

	if m.Locker == nil {
		return fmt.Errorf("Machine '%s' missing Locker", m.ObjectId.Hex())
	}

	// Unlock does not return an error
	m.Locker.Unlock(m.ObjectId.Hex())
	return nil
}

func (m *Machine) releaseEIP() {
	// If machine is stopped after unsuccessful start, it does not have
	// IP updated in its meta - stop here.
	if m.IpAddress == "" {
		return
	}
	// try to release/delete a public elastic IP, if there is an error we don't
	// care (the instance might not have an elastic IP, aka a free user.
	addrs, err := m.Session.AWSClient.AddressesByIP(m.IpAddress)
	if err != nil {
		if !amazon.IsNotFound(err) {
			m.Log.Warning("querying for %q Elastic IPs failed: %s", m.IpAddress, err)
		}
		return
	}

	m.Log.Debug("releasing Elastic IPs (%d): %s", len(addrs), m.IpAddress)

	for _, addr := range addrs {
		m.Log.Debug("Got an elastic IP %+v. Going to relaease it", addr)
		ip := aws.StringValue(addr.PublicIp)

		assocID := aws.StringValue(addr.AssociationId)
		if assocID != "" {
			// if the instance is running, try to disassociate EIP from
			// the instance
			err := m.Session.AWSClient.DisassociateAddress(assocID)
			if err != nil {
				m.Log.Warning("disassociating Elastic IP failed: ip=%s, assocID=%s, err=%s", ip, assocID, err)
			}
		}

		allocID := aws.StringValue(addr.AllocationId)
		if allocID != "" {
			err := m.Session.AWSClient.ReleaseAddress(allocID)
			if err != nil {
				m.Log.Warning("releasing Elastic IP failed: ip=%s, allocID=%s, err=%s", ip, allocID, err)
			}
		}
	}
}
