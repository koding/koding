package main

import (
	"github.com/streadway/amqp"
	"koding/databases/mongo"
	"koding/tools/amqputil"
	"labix.org/v2/mgo"
	"log"
	"strings"
	"time"
)

type Meta struct {
	CreatedAt  time.Time `bson:"createdAt"`
	ModifiedAt time.Time `bson:"modifiedAt"`
}

type Message struct {
	From       string
	RoutingKey string `bson:"routingKey"`
	Body       string
	Meta       Meta
}

func main() {
	startPersisting()
}

func startPersisting() {
	conn := amqputil.CreateConnection("persistence")
	channel, err := conn.Channel()
	if err != nil {
		panic(err)
	}

	if err := channel.ExchangeDeclare(
		"chat",  // exchange name
		"topic", // kind
		false,   //durable
		true,    // auto delete
		false,   // internal
		false,   // no wait
		nil,     // arguments
	); err != nil {
		panic(err)
	}

	if _, err := channel.QueueDeclare(
		"persistence", // queue name
		false,         // durable
		true,          // autodelete
		true,          // exclusive
		false,         // no wait
		nil,           // arguments
	); err != nil {
		panic(err)
	}

	if err := channel.QueueBind(
		"persistence", // queue name
		"#",           // deep wildcard (key)
		"chat",        // exchange name
		false,         // no wait
		nil,           // arguments
	); err != nil {
		panic(err)
	}

	deliveries, err := channel.Consume(
		"persistence", // queue name
		"",            // ctag
		false,         // no-ack
		false,         // exlusive
		false,         // no local
		false,         // no wait
		nil,           // arguments
	)
	if err != nil {
		panic(err)
	}

	errors := make(chan error)

	go consumeAndPersist(deliveries, mongo.GetCollection("jMessages"), errors)

	select {
	case errors <- err:
		log.Printf("Handled an error: %v", err)
	}
}

func consumeAndPersist(
	deliveries <-chan amqp.Delivery,
	messages *mgo.Collection,
	done chan error,
) {
	for d := range deliveries {
		from := d.RoutingKey[strings.LastIndex(d.RoutingKey, ".")+1:]
		t := d.Timestamp
		message := Message{from, d.RoutingKey, string(d.Body), Meta{t, t}}
		messages.Insert(message)
	}
}
