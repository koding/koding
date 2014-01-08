package amqputil

import (
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/config"
	"koding/tools/logger"
	"strings"
)

var log = logger.New("amqputil")

func CreateConnection(component string) *amqp.Connection {
	conn, err := amqp.Dial(amqp.URI{
		Scheme:   "amqp",
		Host:     config.Current.Mq.Host,
		Port:     config.Current.Mq.Port,
		Username: strings.Replace(config.Current.Mq.ComponentUser, "<component>", component, 1),
		Password: config.Current.Mq.Password,
		Vhost:    config.Current.Mq.Vhost,
	}.String())
	if err != nil {
		log.Critical(err.Error())
	}

	go func() {
		for err := range conn.NotifyClose(make(chan *amqp.Error)) {
			log.Error("AMQP connection: " + err.Error())
		}
	}()

	return conn
}

func CreateChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		panic(err)
	}
	go func() {
		for err := range channel.NotifyClose(make(chan *amqp.Error)) {
			log.Warning("AMQP channel: " + err.Error())
		}
	}()
	return channel
}

func DeclareBindConsumeQueue(channel *amqp.Channel, kind, exchange, key string, autoDelete bool) <-chan amqp.Delivery {
	// exchangeName, ExchangeType, durable, autoDelete, internal, noWait, args
	if err := channel.ExchangeDeclare(exchange, kind, false, autoDelete, false, false, nil); err != nil {
		panic(err)
	}
	// name, durable, autoDelete, exclusive, noWait, args Table
	if _, err := channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		panic(err)
	}

	if err := channel.QueueBind("", key, exchange, false, nil); err != nil {
		panic(err)
	}

	stream, err := channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		panic(err)
	}

	return stream
}

func JoinPresenceExchange(channel *amqp.Channel, exchange, serviceType, serviceGenericName, serviceUniqueName string, loadBalancing bool) string {
	if err := channel.ExchangeDeclare(exchange, "x-presence", false, true, false, false, nil); err != nil {
		panic(err)
	}

	queue, err := channel.QueueDeclare("", false, true, true, false, nil)
	if err != nil {
		panic(err)
	}

	routingKey := fmt.Sprintf("serviceType.%s.serviceGenericName.%s.serviceUniqueName.%s", serviceType, serviceGenericName, serviceUniqueName)

	if loadBalancing {
		routingKey += ".loadBalancing"
	}

	if err := channel.QueueBind(queue.Name, routingKey, exchange, false, nil); err != nil {
		panic(err)
	}

	return queue.Name
}
