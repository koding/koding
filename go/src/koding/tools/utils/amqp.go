package utils

import (
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/config"
	"koding/tools/log"
	"os"
	"strings"
)

func CreateAmqpConnection(component string) *amqp.Connection {
	user := strings.Replace(config.Current.Mq.ComponentUser, "<component>", component, 1)
	url := "amqp://" + user + ":" + config.Current.Mq.Password + "@" + config.Current.Mq.Host
	conn, err := amqp.Dial(url)
	if err != nil {
		log.LogError(err, 0)
		os.Exit(1)
	}

	go func() {
		for err := range conn.NotifyClose(make(chan *amqp.Error)) {
			log.Err("AMQP connection: " + err.Error())
			os.Exit(1)
		}
	}()

	return conn
}

func CreateAmqpChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		panic(err)
	}
	go func() {
		for err := range channel.NotifyClose(make(chan *amqp.Error)) {
			log.Warn("AMQP channel: " + err.Error())
		}
	}()
	return channel
}

func DeclareBindConsumeAmqpQueueNoDelete(channel *amqp.Channel, kind, exchange, key string) <-chan amqp.Delivery {
	// TODO: ugly hack, same as below, but autodelete is false for the exchange.

	if err := channel.ExchangeDeclare(exchange, kind, false, false, false, false, nil); err != nil {
		panic(err)
	}

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

func DeclareBindConsumeAmqpQueue(channel *amqp.Channel, kind, exchange, key string) <-chan amqp.Delivery {
	if err := channel.ExchangeDeclare(exchange, kind, false, true, false, false, nil); err != nil {
		panic(err)
	}

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

func DeclareAmqpPresenceExchange(channel *amqp.Channel, exchange, serviceType, serviceGenericName, serviceUniqueName string) {
	if err := channel.ExchangeDeclare(exchange, "x-presence", false, true, false, false, nil); err != nil {
		panic(err)
	}

	if _, err := channel.QueueDeclare("", false, true, true, false, nil); err != nil {
		panic(err)
	}

	routingKey := fmt.Sprintf("serviceType.%s.serviceGenericName.%s.serviceUniqueName.%s", serviceType, serviceGenericName, serviceUniqueName)
	if err := channel.QueueBind("", routingKey, exchange, false, nil); err != nil {
		panic(err)
	}
}
