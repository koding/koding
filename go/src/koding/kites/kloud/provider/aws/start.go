package awsprovider

import (
	"errors"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"

	"github.com/aws/aws-sdk-go/aws"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func (m *Machine) Start(ctx context.Context) (err error) {
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
		if err := m.MarkAsNotInitialized(); err != nil {
			return err
		}

		return errors.New("instance is not available anymore.")
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

	// if it's something else (the error from Instance() call above) return it
	// back
	if err != nil {
		return err
	}

	m.push("Starting machine", 25, machinestate.Starting)

	infoState := amazon.StatusToState(aws.StringValue(instance.State.Name))

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

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
		meta.InstanceType = aws.StringValue(instance.InstanceType)
	}

	m.push("Checking remote machine", 75, machinestate.Starting)
	if !m.IsKlientReady() {
		return errors.New("klient is not ready")
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":          m.IpAddress,
				"meta.instanceName":  meta.InstanceName,
				"meta.instanceId":    meta.InstanceId,
				"meta.instance_type": meta.InstanceType,
				"status.state":       machinestate.Running.String(),
				"status.modifiedAt":  time.Now().UTC(),
				"status.reason":      "Machine is running",
			}},
		)
	})
}
