package oldaws

import (
	"errors"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"

	"github.com/aws/aws-sdk-go/aws"
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

	instance, err := m.Session.AWSClient.Instance()
	if (err == nil && amazon.StatusToState(aws.StringValue(instance.State.Name)) == machinestate.Terminated) ||
		amazon.IsNotFound(err) {
		// This means the instanceId stored in MongoDB doesn't exist anymore in
		// AWS. Probably it was deleted and the state was not updated (possible
		// due a human interaction or a non kloud interaction done somewhere
		// else.)

		return errors.New("instance is not available anymore.")
	}

	// if it's something else (the error from Instance() call above) return it
	// back
	if err != nil {
		return err
	}

	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()
	defer func() {
		if err != nil {
			modelhelper.ChangeMachineState(m.ObjectId, "Machine is marked as "+latestState.String(), latestState)
		}
	}()

	m.PushEvent("Starting machine", 25, machinestate.Starting)

	infoState := amazon.StatusToState(aws.StringValue(instance.State.Name))

	// only start if the machine is stopped, stopping
	if infoState.In(machinestate.Stopped, machinestate.Stopping) {
		// Give time until it's being stopped
		if infoState == machinestate.Stopping {
			time.Sleep(time.Second * 20)
		}

		instance, err := m.Session.AWSClient.Start(ctx)
		if err != nil {
			return err
		}

		m.IpAddress = aws.StringValue(instance.PublicIpAddress)
		m.Meta.InstanceType = aws.StringValue(instance.InstanceType)
	}

	m.PushEvent("Checking remote machine", 75, machinestate.Starting)
	if err := m.WaitKlientReady(); err != nil {
		return err
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":          m.IpAddress,
				"meta.instanceName":  m.Meta.InstanceName,
				"meta.instanceId":    m.Meta.InstanceId,
				"meta.instance_type": m.Meta.InstanceType,
				"status.state":       machinestate.Running.String(),
				"status.modifiedAt":  time.Now().UTC(),
				"status.reason":      "Machine is running",
			}},
		)
	})
}
