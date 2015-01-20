package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/activityemail/activityemail"
	"socialapi/workers/email/emailmodels"
	"socialapi/workers/helper"
	notificationmodels "socialapi/workers/notification/models"
)

var (
	Name = "ActivityEmail"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	// init redis connection
	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(r.Conf, r.Log)

	es := emailmodels.NewEmailSettings(r.Conf)

	handler, err := activityemail.New(
		rmq,
		r.Log,
		es,
	)
	if err != nil {
		r.Log.Error("%s", err.Error())
		return
	}

	r.SetContext(handler)
	r.Register(notificationmodels.Notification{}).OnCreate().Handle((*activityemail.Controller).SendInstantEmail)
	r.Register(notificationmodels.Notification{}).OnUpdate().Handle((*activityemail.Controller).SendInstantEmail)
	r.Listen()
	r.Wait()
}
