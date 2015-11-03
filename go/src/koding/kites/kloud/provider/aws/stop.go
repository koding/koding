package awsprovider

import (
	"fmt"
	"koding/kites/kloud/machinestate"
	"net/http"
	"time"

	awsclient "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/ec2"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"
)

func (m *Machine) Stop(ctx context.Context) (err error) {
	if err := m.UpdateState("Machine is stopping", machinestate.Stopping); err != nil {
		return err
	}

	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()
	defer func() {
		if err != nil {
			m.UpdateState("Machine is marked as "+latestState.String(), latestState)
		}
	}()

	// err = m.Session.AWSClient.Stop(ctx)
	// if err != nil {
	// 	return err
	// }

	// increase the timeout
	timeout := time.Second * 30
	client := &http.Client{
		Transport: &http.Transport{TLSHandshakeTimeout: timeout},
		Timeout:   timeout,
	}

	creds := credentials.NewStaticCredentials(
		"ACCESSKEY",
		"SECRETKEY",
		"",
	)

	awsCfg := &awsclient.Config{
		Credentials: creds,
		HTTPClient:  client,
	}

	awsCfg.Region = "eu-central-1"

	svc := ec2.New(awsCfg)

	id := m.Meta.InstanceId

	fmt.Println("STOPPPING MACHINEEEEEEE")
	_, err = svc.StopInstances(&ec2.StopInstancesInput{
		InstanceIDs: []*string{&id},
	})
	if err != nil {
		return err
	}

	time.Sleep(time.Second * 30)

	latestState = machinestate.Stopped

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"status.state":      machinestate.Stopped.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is stopped",
			}},
		)
	})
}
