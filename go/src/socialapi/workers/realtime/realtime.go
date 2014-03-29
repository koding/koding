package main

import (
	"flag"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/helper"
	realtime "socialapi/workers/realtime/lib"

	"github.com/koding/worker"
)

var (
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		panic("Please define config file with -c")
	}

	conf := config.Read(*flagProfile)

	// create logger for our package
	log := helper.CreateLogger("RealtimeWorker", *flagDebug)

	// panics if not successful
	bongo := helper.MustInitBongo(conf, log)
	// do not forgot to close the bongo connection
	defer bongo.Close()

	// init mongo connection
	modelhelper.Initialize(conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(conf, log)

	handler, err := realtime.NewRealtimeWorkerController(rmq, log)
	if err != nil {
		panic(err)
	}

	listener := worker.NewListener("RealtimeWorker", conf.EventExchangeName, log)
	// blocking
	// listen for events
	listener.Listen(rmq, handler)
	// close consumer
	defer listener.Close()
}
