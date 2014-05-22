package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/helper"
	"socialapi/workers/realtime/realtime"
)

var (
	Name = "Realtime"
)

func main() {
	runner := &helper.Runner{}
	if err := runner.Init(Name); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	modelhelper.Initialize(runner.Conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(runner.Conf, runner.Log)

	handler, err := realtime.NewRealtimeWorkerController(rmq, runner.Log)
	if err != nil {
		panic(err)
	}

	runner.Listen(handler)
	runner.Close()
}
