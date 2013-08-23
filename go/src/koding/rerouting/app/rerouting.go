package main

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/rerouting/lib"
	"koding/tools/amqputil"
	"log"
)

var producer *rerouting.Producer
var defaultPublishingExchange string
var router *rerouting.Router

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

func createProducer() (*rerouting.Producer, error) {
	p := &rerouting.Producer{
		Conn:    nil,
		Channel: nil,
	}

	log.Printf("creating publisher connections")

	p.Conn = amqputil.CreateConnection("routing")
	p.Channel = amqputil.CreateChannel(p.Conn)

	return p, nil
}

func startRouting() {
	c := &rerouting.Consumer{
		Conn:    nil,
		Channel: nil,
	}

	router = rerouting.NewRouter(c, producer)

	var err error

	log.Printf("creating consumer connections")
	c.Conn = amqputil.CreateConnection("routing")
	c.Channel = amqputil.CreateChannel(c.Conn)

	err = c.Channel.ExchangeDeclare("routing-control", "fanout", false, true, false, false, nil)
	if err != nil {
		log.Fatalf("exchange.declare: %s", err)
	}

	if _, err := c.Channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Fatalf("queue.declare: %s", err)
	}

	if err := c.Channel.QueueBind("", "", "routing-control", false, nil); err != nil {
		log.Fatalf("queue.bind: %s", err)
	}

	authStream, err := c.Channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	log.Println("routing started...")
	for msg := range authStream {

		switch msg.RoutingKey {
		case "auth.join":
			join := createAuthMsg(msg)
			if err := router.AddRoute(join); err != nil {
				log.Printf("Error adding route: %v", err)
			}
		case "auth.leave":
			leave := createAuthMsg(msg)
			log.Println(leave)
			if err := router.RemoveRoute(leave); err != nil {
				log.Printf("Error adding route: %v", err)
			}
		default:
			log.Println("unknown routing key: ", msg.RoutingKey)
		}
	}
}

func createAuthMsg(msg amqp.Delivery) *rerouting.AuthMsg {
	var join rerouting.AuthMsg

	if err := json.Unmarshal(msg.Body, &join); err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	if join.PublishingExchange == nil {
		join.PublishingExchange = &defaultPublishingExchange
	}

	return &join
}
