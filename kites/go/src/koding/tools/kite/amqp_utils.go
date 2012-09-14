package kite

import (
	"github.com/streadway/amqp"
)

func createConn(uri string) *amqp.Connection {
	conn, err := amqp.Dial(uri)
	if err != nil {
		panic(err)
	}
	return conn
}

func createChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		panic(err)
	}
	return channel
}

func declareBindConsumeQueue(channel *amqp.Channel, queue, key, exchange string) <-chan amqp.Delivery {
	err := channel.ExchangeDeclare(exchange, "topic", true, true, false, false, nil)
	if err != nil {
		panic(err)
	}

	_, err = channel.QueueDeclare(queue, false, true, false, false, nil)
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
