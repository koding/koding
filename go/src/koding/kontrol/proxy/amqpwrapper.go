package main

import (
	"github.com/streadway/amqp"
	"koding/kontrol/helper"
	"koding/tools/config"
	"log"
)

type Consumer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	tag     string
	done    chan error
}

type AmqpStream struct {
	input   <-chan amqp.Delivery
	channel *amqp.Channel
	uuid    string
}

func setupAmqp() *AmqpStream {
	c := &Consumer{
		conn:    nil,
		channel: nil,
		tag:     "",
		done:    make(chan error),
	}

	appId := helper.CustomHostname()

	user := config.Current.Kontrold.RabbitMq.Login
	password := config.Current.Kontrold.RabbitMq.Password
	host := config.Current.Kontrold.RabbitMq.Host
	port := config.Current.Kontrold.RabbitMq.Port

	c.conn = helper.CreateAmqpConnection(user, password, host, port)
	c.channel = helper.CreateChannel(c.conn)
	err := c.channel.ExchangeDeclare("infoExchange", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	if _, err := c.channel.QueueDeclare("proxy-handler-"+appId, false, true, false, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	proxyId := "output.proxy." + appId
	if err := c.channel.QueueBind("proxy-handler-"+appId, proxyId, "infoExchange", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	stream, err := c.channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	return &AmqpStream{stream, c.channel, appId}
}

func (a *AmqpStream) Publish(exchange, routingKey string, data []byte) {
	appId := helper.CustomHostname()
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
		AppId:           appId,
	}

	a.channel.Publish(exchange, routingKey, false, false, msg)
}
