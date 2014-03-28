package main

import (
	"flag"
	"koding/tools/config"
	"os"
	"socialapi/db"
	topicfeed "socialapi/workers/topicfeed/lib"
	"github.com/koding/rabbitmq"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"github.com/koding/broker"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

func init() {
	logHandler = logging.NewWriterHandler(os.Stderr)
	logHandler.Colorize = true
	log.SetHandler(logHandler)
}

var (
	Bongo       *bongo.Bongo
	log         = logging.NewLogger("TopicFeedWorker")
	logHandler  *logging.WriterHandler
	conf        *config.Config
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	handler     *topicfeed.TopicFeedController
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c", "")
	}

	conf = config.MustConfig(*flagProfile)
	setLogLevel()

	// create logger for our package
	log = helper.CreateLogger("TopicFeedWorker", *flagDebug)

	// panics if not successful
	Bongo = helper.MustInitBongo(conf, log)
	// do not forgot to close the bongo connection
	defer Bongo.Close()

	// create message handler
	handler = topicfeed.NewTopicFeedController(log)

	// blocking
	topicfeed.Listen(rabbitmq.New(rmqConf, log), startHandler)
	defer topicfeed.Consumer.Shutdown()
}

func startHandler() func(delivery amqp.Delivery) {
	log.Info("Worker Started to Consume")
	return func(delivery amqp.Delivery) {
		err := handler.HandleEvent(delivery.Type, delivery.Body)
		switch err {
		case nil:
			delivery.Ack(false)
		case topicfeed.HandlerNotFoundErr:
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

func setLogLevel() {
	var logLevel logging.Level

	if *flagDebug {
		logLevel = logging.DEBUG
	} else {
		logLevel = logging.INFO
	}
	log.SetLevel(logLevel)
	logHandler.SetLevel(logLevel)
}
