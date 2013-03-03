package amqputil

import (
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/config"
	"koding/tools/log"
	"os"
	"strings"
)

func CreateConnection(component string) *amqp.Connection {
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

func CreateChannel(conn *amqp.Connection) *amqp.Channel {
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

func DeclareBindConsumeQueue(channel *amqp.Channel, kind, exchange, key string, autoDelete bool) <-chan amqp.Delivery {
	if err := channel.ExchangeDeclare(exchange, kind, false, autoDelete, false, false, nil); err != nil {
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

func DeclarePresenceExchange(channel *amqp.Channel, exchange, serviceType, serviceGenericName, serviceUniqueName string) {
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
