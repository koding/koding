package main

import (
	"flag"
	"koding/rerouting/router"
	"koding/tools/amqputil"
	"koding/tools/config"
	"koding/tools/logger"
)

var (
	log         = logger.New("rerouting")
	conf        *config.Config
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")

	defaultPublishingExchange string
	producer                  *rerouting.Producer
	router                    *rerouting.Router
)

func main() {
	flag.Parse()
	log.Info("routing worker started")
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	conf = config.MustConfig(*flagProfile)

	var logLevel logger.Level
	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.GetLoggingLevelFromConfig("rerouting", *flagProfile)
	}
	log.SetLevel(logLevel)

	var err error
	producer, err = createProducer()
	if err != nil {
		log.Fatal("create producer: %v", err)
	}

	defaultPublishingExchange = "broker"

	startRouting()
}

func createProducer() (*rerouting.Producer, error) {
	p := &rerouting.Producer{
		Conn:    nil,
		Channel: nil,
	}

	log.Info("creating publisher connections")

	p.Conn = amqputil.CreateConnection(conf, "routing")
	p.Channel = amqputil.CreateChannel(p.Conn)

	return p, nil
}

func startRouting() {
	c := &rerouting.Consumer{
		Conn:    nil,
		Channel: nil,
	}

	router = rerouting.NewRouter(c, producer, *flagProfile)

	var err error

	log.Info("creating consumer connections")
	c.Conn = amqputil.CreateConnection(conf, "routing")
	c.Channel = amqputil.CreateChannel(c.Conn)

	err = c.Channel.ExchangeDeclare("routing-control", "fanout", false, true, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	if _, err := c.Channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.Channel.QueueBind("", "", "routing-control", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	authStream, err := c.Channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	log.Info("routing started...")
	for msg := range authStream {

		switch msg.RoutingKey {
		case "auth.join":
			if err := router.AddRoute(&msg); err != nil {
				log.Info("Error adding route: %v", err)
			}
		case "auth.leave":
			if err := router.RemoveRoute(&msg); err != nil {
				// log.Info("Error removing route: %v", err)
			}
		default:
			// log.Info("unknown routing key: ", msg.RoutingKey)
		}
	}
}
