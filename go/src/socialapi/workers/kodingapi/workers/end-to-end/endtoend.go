// NOTE about usage
// This file is created for testing
package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"os"
	"socialapi/config"
	"socialapi/workers/kodingapi/workers/kitworker"
	"socialapi/workers/kodingapi/workers/machine"
	"time"

	"github.com/go-kit/kit/loadbalancer"
	"github.com/go-kit/kit/loadbalancer/static"
	"github.com/go-kit/kit/log"
	"github.com/koding/runner"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2/bson"
)

var (
	// Name holds the worker name
	Name = "KodingApi"
)

func main() {

	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	logger := log.NewLogfmtLogger(os.Stderr)

	ctx := context.Background()

	profileApiEndpoints := []string{
		"localhost:8080",
	}

	lbCreator := func(factory loadbalancer.Factory) loadbalancer.LoadBalancer {
		publisher := static.NewPublisher(
			profileApiEndpoints,
			factory,
			logger,
		)

		return loadbalancer.NewRoundRobin(publisher)
	}

	clientOpts := &kitworker.ClientOption{
		QPS:                 100,
		LoadBalancerCreator: lbCreator,
	}

	machineClient := machine.NewMachineClient(
		clientOpts,
		logger,
	)

	machineAndUser, err := getMachineAndUser()
	if err != nil {
		fmt.Errorf("err while getting machine and user: %v", err)
		return
	}

	machineId := machineAndUser.ObjectId.Hex()

	mach, err := machineClient.GetMachine(ctx, &machineId)
	if err != nil {
		fmt.Errorf("err while getting machine : %v", err)
		return
	}
	fmt.Println("machine is", mach)

	machineStatus, err := machineClient.GetMachineStatus(ctx, &machineId)
	if err != nil {
		fmt.Errorf("err while getting machine : %v", err)
		return
	}
	fmt.Println("machine is", machineStatus)
}

func getMachineAndUser() (*models.Machine, error) {
	m := &models.Machine{
		ObjectId:    bson.NewObjectId(),
		Uid:         bson.NewObjectId().Hex(),
		QueryString: "",
		IpAddress:   "",
		Domain:      "",
		Provider:    "koding",
		Label:       "",
		Slug:        "",
		Users: []models.MachineUser{
			// real owner
			models.MachineUser{
				Id:    bson.NewObjectId(),
				Sudo:  true,
				Owner: true,
			},
			// secondary owner
			models.MachineUser{
				Id:    bson.NewObjectId(),
				Sudo:  false,
				Owner: true,
			},
			// has sudo but not owner
			models.MachineUser{
				Id:    bson.NewObjectId(),
				Sudo:  true,
				Owner: false,
			},
			// random user
			models.MachineUser{
				Id:    bson.NewObjectId(),
				Sudo:  false,
				Owner: false,
			},
		},
		CreatedAt: time.Now().UTC(),
		Status: models.MachineStatus{
			State:      "running",
			ModifiedAt: time.Now().UTC(),
		},
		Assignee:    models.MachineAssignee{},
		UserDeleted: false,
	}

	err := modelhelper.CreateMachine(m)
	if err != nil {
		return nil, err
	}

	return m, nil
}
