package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/emailnotifier/controller"
	"socialapi/workers/helper"

	"github.com/koding/worker"
)

var (
	Name = "EmailNotifier"
)

func main() {
	runner := &helper.Runner{}
	if err := runner.Init(Name); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	modelhelper.Initialize(runner.Conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(runner.Conf, runner.Log)

	es := &emailnotifier.EmailSettings{
		Username: conf.SendGrid.Username,
		Password: conf.SendGrid.Password,
		FromMail: conf.SendGrid.FromMail,
		FromName: conf.SendGrid.FromName,
	}

	handler, err := emailnotifier.NewEmailNotifierWorkerController(
		rmq,
		runner.Log,
		es,
	)
	if err != nil {
		panic(err)
	}

	listener := worker.NewListener(
		helper.WrapWithVersion(Name, flagVersion),
		helper.WrapWithVersion(conf.EventExchangeName, flagVersion),
		log,
	)

	runner.Listen(handler)
	runner.Close()
}
