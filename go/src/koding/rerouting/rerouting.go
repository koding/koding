package main

import (
	"koding/artifact"
	"koding/rerouting/router"
	"koding/tools/amqputil"
	"koding/tools/config"
	"koding/tools/logger"

	"github.com/koding/multiconfig"
)

var (
	Name = "rerouting"
	log  = logger.New(Name)
	conf *config.Config

	defaultPublishingExchange string
	producer                  *rerouting.Producer
	router                    *rerouting.Router
)

func main() {
	loader := multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG"},
		&multiconfig.FlagLoader{},
	)

	conf = new(config.Config)
	loader.Load(conf)

	log.Info("routing worker started")

	logLevel := logger.GetLoggingLevelFromConfig("rerouting", "")
	log.SetLevel(logLevel)

	var err error
	producer, err = createProducer()
	if err != nil {
		log.Fatal("create producer ", err)
	}

	defaultPublishingExchange = "broker"

	go artifact.StartDefaultServer(Name, conf.Rerouting.Port)

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

	router = rerouting.NewRouter(c, producer, "")

	var err error

	log.Info("creating consumer connections")
	c.Conn = amqputil.CreateConnection(conf, "routing")
	c.Channel = amqputil.CreateChannel(c.Conn)

	err = c.Channel.ExchangeDeclare("routing-control", "fanout", false, true, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: ", err)
	}

	if _, err := c.Channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Fatal("queue.declare: ", err)
	}

	if err := c.Channel.QueueBind("", "", "routing-control", false, nil); err != nil {
		log.Fatal("queue.bind: ", err)
	}

	authStream, err := c.Channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: ", err)
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
