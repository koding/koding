package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/chatnotifier/chatemailfeeder/feeder"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
)

var Name = "ChatEmailNotifier"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// mongo connection is used for getting account emails and email settings
	modelhelper.Initialize(r.Conf.Mongo)

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	rmq := helper.NewRabbitMQ(r.Conf, r.Log)

	handler, err := feeder.New(r.Log)

	r.ShutdownHandler = handler.Shutdown

	r.Listen()
	r.Wait()
}
