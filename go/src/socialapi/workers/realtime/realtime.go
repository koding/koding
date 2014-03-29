package main

import (
	"flag"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	socialconfig "socialapi/config"
	"socialapi/workers/helper"
	realtime "socialapi/workers/realtime/lib"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
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

	conf = config.MustConfig(*flagProfile)

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

	listener := worker.NewListener("RealtimeWorker", socialconfig.EventExchangeName)
	// blocking
	// listen for events
	listener.Listen(rmq, startHandler)
	// close consumer
	defer listener.Close()
}

func startHandler() func(delivery amqp.Delivery) {
	log.Info("Worker Started to Consume")
	return func(delivery amqp.Delivery) {
		err := handler.HandleEvent(delivery.Type, delivery.Body)
		switch err {
		case nil:
			delivery.Ack(false)
		case realtime.HandlerNotFoundErr:
			log.Notice("unknown event type (%s) recieved, \n deleting message from RMQ", delivery.Type)
			delivery.Ack(false)
		case gorm.RecordNotFound:
			log.Warning("Record not found in our db (%s) recieved, \n deleting message from RMQ", string(delivery.Body))
			delivery.Ack(false)
		default:
			// add proper error handling
			// instead of puttting message back to same queue, it is better
			// to put it to another maintenance queue/exchange
			log.Error("an error occured %s, \n putting message back to queue", err)
			// multiple false
			// reque true
			delivery.Nack(false, true)
		}
	}
}
