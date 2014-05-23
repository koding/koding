package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/emailnotifier/controller"
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

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(r.Conf, r.Log)

	es := &emailnotifier.EmailSettings{
		Username: conf.SendGrid.Username,
		Password: conf.SendGrid.Password,
		FromMail: conf.SendGrid.FromMail,
		FromName: conf.SendGrid.FromName,
	}

	handler, err := emailnotifier.NewEmailNotifierWorkerController(
		rmq,
		r.Log,
		es,
	)
	if err != nil {
		panic(err)
	}

	r.Listen(handler)
	r.Close()
}
