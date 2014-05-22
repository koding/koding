package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/helper"
	"socialapi/workers/notification/controller"
)

var (
	Name = "Notification"
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

	cacheEnabled := runner.Conf.Notification.CacheEnabled
	if cacheEnabled {
		// init redis
		redisConn := helper.MustInitRedisConn(runner.Conf.Redis)
		defer redisConn.Close()
	}

	handler, err := notification.NewNotificationWorkerController(
		rmq,
		runner.Log,
		cacheEnabled,
	)
	if err != nil {
		panic(err)
	}

	runner.Listen(handler)
	runner.Close()
}
