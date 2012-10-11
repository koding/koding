package utils

import (
	"github.com/streadway/amqp"
	"koding/config"
	"koding/tools/log"
	"time"
)

func AmqpAutoReconnect(handler func(consumeConn, publishConn *amqp.Connection)) {
	for !ShuttingDown {
		func() {
			defer time.Sleep(time.Second)
			defer log.RecoverAndLog()

			log.Info("Connecting to AMQP server...")

			consumeConn := CreateAmqpConnection(config.Current.AmqpUri)
			defer consumeConn.Close()
			publishConn := CreateAmqpConnection(config.Current.AmqpUri)
			defer publishConn.Close()

			log.Info("Successfully connected to AMQP server.")

			handler(consumeConn, publishConn)

			if !ShuttingDown {
				log.Warn("Connection to AMQP server lost.")
			}
		}()
	}
}

func CreateAmqpConnection(uri string) *amqp.Connection {
	conn, err := amqp.Dial(uri)
	if err != nil {
		panic(err)
	}
	go func() {
		for err := range conn.NotifyClose(make(chan *amqp.Error)) {
			log.Warn("AMQP connection: " + err.Error())
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

func DeclareAmqpExchange(channel *amqp.Channel, exchange string) {
	err := channel.ExchangeDeclare(exchange, "topic", true, true, false, false, nil)
	if err != nil {
		panic(err)
	}
}

func DeclareBindConsumeAmqpQueue(channel *amqp.Channel, queue, key, exchange string, autodelete bool) <-chan amqp.Delivery {
	DeclareAmqpExchange(channel, exchange)

	_, err := channel.QueueDeclare(queue, false, autodelete, false, false, nil)
	if err != nil {
		panic(err)
	}

	err = channel.QueueBind(queue, key, exchange, false, nil)
	if err != nil {
		panic(err)
	}

	stream, err := channel.Consume(queue, "", true, false, false, false, nil)
	if err != nil {
		panic(err)
	}

	return stream
}
