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
		Username: r.Conf.SendGrid.Username,
		Password: r.Conf.SendGrid.Password,
		FromMail: r.Conf.SendGrid.FromMail,
		FromName: r.Conf.SendGrid.FromName,
	}

	handler, err := emailnotifier.New(
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
