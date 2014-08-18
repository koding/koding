package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/emailnotifier/emailnotifier"
	"socialapi/workers/emailnotifier/models"
	"socialapi/workers/helper"
	notificationmodels "socialapi/workers/notification/models"
)

var (
	Name = "EmailNotifier"
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

	es := &models.EmailSettings{
		Username:           r.Conf.SendGrid.Username,
		Password:           r.Conf.SendGrid.Password,
		DefaultFromMail:    r.Conf.SendGrid.DefaultFromMail,
		DefaultFromAddress: r.Conf.SendGrid.DefaultFromAddress,
		ForcedRecipient:    r.Conf.SendGrid.ForcedRecipient,
	}

	handler, err := emailnotifier.New(
		rmq,
		r.Log,
		es,
	)
	if err != nil {
		r.Log.Error("%s", err.Error())
		return
	}

	r.SetContext(handler)
	r.Register(notificationmodels.Notification{}).OnCreate().Handle((*emailnotifier.Controller).SendInstantEmail)
	r.Register(notificationmodels.Notification{}).OnUpdate().Handle((*emailnotifier.Controller).SendInstantEmail)
	r.Listen()
	r.Wait()
}
