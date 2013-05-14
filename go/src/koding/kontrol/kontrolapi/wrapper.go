package main

import (
	"github.com/streadway/amqp"
	"koding/kontrol/helper"
)

type AmqpWrapper struct {
	channel *amqp.Channel
	input   <-chan amqp.Delivery
}

func setupAmqp() *AmqpWrapper {
	connection := helper.CreateAmqpConnection()
	channel := helper.CreateChannel(connection)
	stream := helper.CreateStream(channel, "topic", "infoExchange", "webApi", "output.webapi", true, false)

	return &AmqpWrapper{
		channel: channel,
		input:   stream,
	}
}

func (a *AmqpWrapper) Publish(data []byte) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
	}

	a.channel.Publish("infoExchange", "input.api", false, false, msg)
}
