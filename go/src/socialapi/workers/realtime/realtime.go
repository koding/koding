package main

import (
	"flag"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/helper"
	realtime "socialapi/workers/realtime/lib"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/worker"
)

var (
	Bongo       *bongo.Bongo
	log         = logging.NewLogger("RealtimeWorker")
	conf        *config.Config
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	handler     *realtime.RealtimeWorkerController
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c", "")
	}

	conf = config.Read(*flagProfile)

	// create logger for our package
	log = helper.CreateLogger("TopicFeedWorker", *flagDebug)

	// panics if not successful
	Bongo = helper.MustInitBongo(conf, log)
	// do not forgot to close the bongo connection
	defer Bongo.Close()

	// init mongo connection
	modelhelper.Initialize(conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(conf, log)

	h, err := realtime.NewRealtimeWorkerController(rmq, log)
	if err != nil {
		panic(err)
	}

	handler = h

	listener := worker.NewListener("RealtimeWorker", conf.EventExchangeName, log)
	// blocking
	// listen for events
	listener.Listen(rmq, handler)
	// close consumer
	defer listener.Close()
}
