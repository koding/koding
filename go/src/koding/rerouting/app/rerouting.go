package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/rerouting/lib"
	"koding/tools/amqputil"
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

var producer *Producer
var defaultPublishingExchange string

func main() {
	log.Println("routing worker started")

	var err error
	producer, err = createProducer()
	if err != nil {
		log.Printf("create producer: %v", err)
	}

	defaultPublishingExchange = "broker"

	startRouting()
}

func createProducer() (*Producer, error) {
	p := &Producer{
		conn:    nil,
		channel: nil,
	}

	log.Printf("creating publisher connections")

	p.conn = amqputil.CreateConnection("routing")
	p.channel = amqputil.CreateChannel(p.conn)

	return p, nil
}

func startRouting() {
	c := &Consumer{
		conn:    nil,
		channel: nil,
		tag:     "",
	}

	var err error

	log.Printf("creating consumer connections")
	c.conn = amqputil.CreateConnection("routing")
	c.channel = amqputil.CreateChannel(c.conn)

	err = c.channel.ExchangeDeclare("routing-control", "fanout", false, true, false, false, nil)
	if err != nil {
		log.Fatalf("exchange.declare: %s", err)
	}

	if _, err := c.channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Fatalf("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind("", "", "routing-control", false, nil); err != nil {
		log.Fatalf("queue.bind: %s", err)
	}

	authStream, err := c.channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	log.Println("routing started...")
	for msg := range authStream {

		switch msg.RoutingKey {
		case "auth.join":
			handleAuthJoin(c, msg)
		case "auth.leave":
			handleAuthLeave(c, msg)
		default:
			log.Println("unknown routing key: ", msg.RoutingKey)
		}
	}
}

func handleAuthJoin(c *Consumer, msg amqp.Delivery) {
	var join rerouting.JoinMsg

	err := json.Unmarshal(msg.Body, &join)
	if err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	if join.PublishingExchange == nil {
		join.PublishingExchange = &defaultPublishingExchange
	}

	join.ConsumerTag = generateUniqueConsumerTag(join.BindingKey)

	errors := make(chan error)

	go consumeAndRepublish(c, join, errors)

}

func handleAuthLeave(c *Consumer, msg amqp.Delivery) {

}

func generateUniqueConsumerTag(bindingKey string) string {
	r := make([]byte, 32/8)
	rand.Read(r)
	return bindingKey + "." + base64.StdEncoding.EncodeToString(r)
}

func consumeAndRepublish(
	c *Consumer,
	join rerouting.JoinMsg,
	done chan error,
) {
	// used fo debug
	// log.Printf("Consume from:\n bindingExchange %s\n bindingKey %s\n routingKey %s\n consumerTag %s\n",
	//  bindingExchange, bindingKey, routingKey, consumerTag)

	routingKey := join.RoutingKey

	if len(join.Suffix) > 0 {
		routingKey += join.Suffix
	}

	join.Channel = c.channel

}
