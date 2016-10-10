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

func (m *Machine) Stop(ctx context.Context) error {
	err := m.stop(ctx)
	if err != nil {
		return stack.NewEventerError(err)
	}

	return nil
}

func (m *Machine) stop(ctx context.Context) (err error) {
	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()

	if err := modelhelper.ChangeMachineState(m.ObjectId, "Machine is stopping", machinestate.Stopping); err != nil {
		return err
	}

	defer func() {
		if err != nil {
			modelhelper.ChangeMachineState(m.ObjectId, "Machine is marked as "+latestState.String(), latestState)
		}
	}()

	m.PushEvent("Stopping machine", 25, machinestate.Stopping)

	var id management.OperationID
	if id, err = m.AzureVMClient.ShutdownRole(m.Meta.HostedServiceID, m.Meta.InstanceID, m.Meta.InstanceID, virtualmachine.PostShutdownActionStoppedDeallocated); err != nil {
		return err
	}

	if err = m.AzureClient.WaitForOperation(id, nil); err != nil {
		return err
	}

	m.PushEvent("Machine stopped", 100, machinestate.Stopped)

	latestState = machinestate.Stopped

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"status.state":      machinestate.Stopped.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is stopped",
			}},
		)
	})
}
