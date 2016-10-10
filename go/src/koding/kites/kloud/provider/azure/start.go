package azure

import (
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"

	"github.com/Azure/azure-sdk-for-go/management"
	"github.com/Azure/azure-sdk-for-go/management/virtualmachine"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func (m *Machine) Start(ctx context.Context) error {
	err := m.start(ctx)
	if err != nil {
		return stack.NewEventerError(err)
	}

	return nil
}

func (m *Machine) start(ctx context.Context) (err error) {
	if err := modelhelper.ChangeMachineState(m.ObjectId, "Machine is starting", machinestate.Starting); err != nil {
		return err
	}

	// update the state to intial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below.
	latestState := m.State()
	defer func() {
		if err != nil {
			modelhelper.ChangeMachineState(m.ObjectId, "Machine is marked as "+latestState.String(), latestState)
		}
	}()

	m.PushEvent("Starting machine", 25, machinestate.Starting)

	var id management.OperationID
	if id, err = m.AzureVMClient.StartRole(m.Meta.HostedServiceID, m.Meta.InstanceID, m.Meta.InstanceID); err != nil {
		return err
	}

	m.PushEvent("Checking remote machine", 75, machinestate.Starting)

	if err = m.AzureClient.WaitForOperation(id, nil); err != nil {
		return err
	}

	dep, err := m.AzureVMClient.GetDeployment(m.Meta.HostedServiceID, m.Meta.InstanceID)
	if err != nil {
		return err
	}

	if err := m.WaitKlientReady(); err != nil {
		return err
	}

	for _, ip := range dep.VirtualIPs {
		if ip.Type == virtualmachine.IPAddressTypePrivate {
			continue
		}

		m.IpAddress = ip.Address
		break
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":         m.IpAddress,
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is running",
			}},
		)
	})
}
