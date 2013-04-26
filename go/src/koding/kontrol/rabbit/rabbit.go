package main

import (
	"github.com/streadway/amqp"
	"log"
)

type Consumer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	tag     string
}

type Producer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

func main() {
	log.Println("kontrol rabbitproxy started")

	startRouting()
}

func startRouting() {
	c := &Consumer{
		conn:    nil,
		channel: nil,
		tag:     "",
	}

	var err error

	log.Printf("creating consumer connections")

	user := "guest"
	password := "guest"
	host := "localhost"
	port := "5672"

	url := "amqp://" + user + ":" + password + "@" + host + ":" + port
	c.conn, err = amqp.Dial(url)
	if err != nil {
		log.Fatal(err)
	}

	c.channel, err = c.conn.Channel()
	if err != nil {
		log.Fatal(err)
	}

	err = c.channel.ExchangeDeclare("kontrol-rabbitproxy", "topic", false, true, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	if _, err := c.channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind("", "", "kontrol-rabbitproxy", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	authStream, err := c.channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	log.Println("routing started...")
	for msg := range authStream {
		log.Printf("got %dB message data: [%v]-[%s] %s",
			len(msg.Body),
			msg.DeliveryTag,
			msg.RoutingKey,
			msg.Body)
	}
}
