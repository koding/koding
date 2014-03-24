package main

import (
	"flag"
	"koding/messaging/rabbitmq"
	"koding/tools/config"
	"socialapi/db"
	topicfeed "socialapi/workers/topicfeed/lib"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"github.com/koding/broker"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

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

var (
	Bongo       *bongo.Bongo
	log         = logging.NewLogger("TopicFeedWorker")
	conf        *config.Config
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	handler     = topicfeed.NewTopicFeedController(log)
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c", "")
	}

	conf = config.MustConfig(*flagProfile)
	setLogLevel()

	initBongo(conf)
	// blocking
	topicfeed.Listen(rabbitmq.New(conf), startHandler)
	defer topicfeed.Consumer.Shutdown()
}

func initBongo(c *config.Config) {
	bConf := &broker.Config{
		Host:     c.Mq.Host,
		Port:     c.Mq.Port,
		Username: c.Mq.ComponentUser,
		Password: c.Mq.Password,
		Vhost:    c.Mq.Vhost,
	}

	broker := broker.New(bConf, log)
	Bongo = bongo.New(broker, db.DB)
	Bongo.Connect()
}

func setLogLevel() {
	var logLevel logging.Level

	if *flagDebug {
		logLevel = logging.DEBUG
	} else {
		logLevel = logging.INFO
	}
	log.SetLevel(logLevel)
}
