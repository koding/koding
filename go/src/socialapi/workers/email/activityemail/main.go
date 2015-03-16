package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/activityemail/activityemail"
	"socialapi/workers/email/emailmodels"
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
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// init redis connection
	redisConn := runner.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	es := emailmodels.NewEmailSettings(appConfig)

	handler := activityemail.New(
		r.Bongo.Broker.MQ,
		r.Log,
		es,
	)

	r.SetContext(handler)
	r.Register(notificationmodels.Notification{}).OnCreate().Handle((*activityemail.Controller).SendInstantEmail)
	r.Register(notificationmodels.Notification{}).OnUpdate().Handle((*activityemail.Controller).SendInstantEmail)
	r.Listen()
	r.Wait()
}
