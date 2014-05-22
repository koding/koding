package main

import (
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/emailnotifier/controller"
	"socialapi/workers/helper"

	"github.com/koding/worker"
)

var (
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	Name        = "EmailNotifier"
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		fmt.Println("Please define config file with -c", "Exiting...")
		return
	}

	conf := config.MustRead(*flagProfile)

	// create logger for our package
	log := helper.CreateLogger(Name, *flagDebug)

	// panics if not successful
	bongo := helper.MustInitBongo(Name, conf, log)
	// do not forgot to close the bongo connection
	defer bongo.Close()

	// init mongo connection
	modelhelper.Initialize(conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(conf, log)

	es := &emailnotifier.EmailSettings{
		Username: conf.SendGrid.Username,
		Password: conf.SendGrid.Password,
		FromMail: conf.SendGrid.FromMail,
		FromName: conf.SendGrid.FromName,
	}
	handler, err := emailnotifier.NewEmailNotifierWorkerController(rmq, log, es)
	if err != nil {
		panic(err)
	}

	listener := worker.NewListener(Name, conf.EventExchangeName, log)
	// blocking
	// listen for events
	listener.Listen(rmq, handler)
	// close consumer
	defer listener.Close()
}
