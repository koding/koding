package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/emailnotifier/controller"
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

	handler, err := controller.New(
		rmq,
		r.Log,
		es,
	)
	if err != nil {
		panic(err)
	}
	r.Listen(handler)
	r.Wait()
}
