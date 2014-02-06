package amqputil

import (
	"fmt"
	"koding/tools/config"
	"koding/tools/logger"
	"strings"

	"github.com/streadway/amqp"
)

var (
	log  = logger.New("ampqutil")
	conf *config.Config
)

func SetupAMQP(profile string) {
	conf = config.MustConfig(profile)
}

func CreateConnection(component string) *amqp.Connection {
	if conf == nil {
		log.Fatal("Configuration is not defined. Please call SetupAMQP() before you proceed.")
	}

	conn, err := amqp.Dial(amqp.URI{
		Scheme:   "amqp",
		Host:     conf.Mq.Host,
		Port:     conf.Mq.Port,
		Username: strings.Replace(conf.Mq.ComponentUser, "<component>", component, 1),
		Password: conf.Mq.Password,
		Vhost:    conf.Mq.Vhost,
	}.String())
	if err != nil {
		log.Fatal(err)
	}

	go func() {
		for err := range conn.NotifyClose(make(chan *amqp.Error)) {
			log.Fatal("AMQP connection: %v", err)
		}
	}()

	return conn
}

func CreateChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		log.Panic("%v", err)
	}
	go func() {
		for err := range channel.NotifyClose(make(chan *amqp.Error)) {
			log.Warning("AMQP channel: %v", err)
		}
	}()
	return channel
}

func DeclareBindConsumeQueue(channel *amqp.Channel, kind, exchange, key string, autoDelete bool) <-chan amqp.Delivery {
	// exchangeName, ExchangeType, durable, autoDelete, internal, noWait, args
	if err := channel.ExchangeDeclare(exchange, kind, false, autoDelete, false, false, nil); err != nil {
		log.Panic("%v", err)
	}
	// name, durable, autoDelete, exclusive, noWait, args Table
	if _, err := channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Panic("%v", err)
	}

	if err := channel.QueueBind("", key, exchange, false, nil); err != nil {
		log.Panic("%v", err)
	}

	stream, err := channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Panic("%v", err)
	}

	return stream
}

func JoinPresenceExchange(channel *amqp.Channel, exchange, serviceType, serviceGenericName, serviceUniqueName string, loadBalancing bool) string {
	if err := channel.ExchangeDeclare(exchange, "x-presence", false, true, false, false, nil); err != nil {
		log.Panic("%v", err)
	}

	queue, err := channel.QueueDeclare("", false, true, true, false, nil)
	if err != nil {
		log.Panic("%v", err)
	}

	routingKey := fmt.Sprintf("serviceType.%s.serviceGenericName.%s.serviceUniqueName.%s", serviceType, serviceGenericName, serviceUniqueName)

	if loadBalancing {
		routingKey += ".loadBalancing"
	}

	if err := channel.QueueBind(queue.Name, routingKey, exchange, false, nil); err != nil {
		log.Panic("%v", err)
	}

	return queue.Name
}
