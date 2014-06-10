package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/manager"
	"socialapi/workers/common/runner"
	"socialapi/workers/emailnotifier/emailnotifier"
	"socialapi/workers/emailnotifier/models"
	"socialapi/workers/helper"
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
	redisConn := helper.MustInitRedisConn(r.Conf.Redis)
	defer redisConn.Close()

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(r.Conf, r.Log)

	es := &models.EmailSettings{
		Username:        r.Conf.SendGrid.Username,
		Password:        r.Conf.SendGrid.Password,
		FromMail:        r.Conf.SendGrid.FromMail,
		FromName:        r.Conf.SendGrid.FromName,
		ForcedRecipient: r.Conf.SendGrid.ForcedRecipient,
	}

	handler, err := emailnotifier.New(
		rmq,
		r.Log,
		es,
	)
	if err != nil {
		panic(err)
	}

	m := manager.New()
	m.Controller(handler)
	m.HandleFunc("notification.notification_created", (*emailnotifier.Controller).SendInstantEmail)
	m.HandleFunc("notification.notification_updated", (*emailnotifier.Controller).SendInstantEmail)

	r.Listen(m)
	r.Wait()
}
