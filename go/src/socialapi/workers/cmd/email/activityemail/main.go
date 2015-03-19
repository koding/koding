package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/activityemail"
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
	defer modelhelper.Close()

	// init redis connection
	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	handler := activityemail.New(
		r.Bongo.Broker.MQ,
		r.Log,
	)

	r.SetContext(handler)
	r.Register(notificationmodels.Notification{}).OnCreate().Handle((*activityemail.Controller).SendInstantEmail)
	r.Register(notificationmodels.Notification{}).OnUpdate().Handle((*activityemail.Controller).SendInstantEmail)
	r.Listen()
	r.Wait()
}
