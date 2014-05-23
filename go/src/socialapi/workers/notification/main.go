package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/notification/controller"
)

var (
	Name = "Notification"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(r.Conf, r.Log)

	cacheEnabled := r.Conf.Notification.CacheEnabled
	if cacheEnabled {
		// init redis
		redisConn := helper.MustInitRedisConn(r.Conf.Redis)
		defer redisConn.Close()
	}

	handler, err := notification.NewNotificationWorkerController(
		rmq,
		r.Log,
		cacheEnabled,
	)
	if err != nil {
		panic(err)
	}

	r.Listen(handler)
	r.Close()
}
