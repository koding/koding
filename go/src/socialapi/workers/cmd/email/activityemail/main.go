package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/email/activityemail"
	notificationmodels "socialapi/workers/notification/models"

	"github.com/koding/runner"
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
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// init redis connection
	redisConn := runner.MustInitRedisConn(r.Conf)
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
