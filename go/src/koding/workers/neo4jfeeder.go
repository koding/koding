package main

import (
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/amqputil"
	"koding/migrators/mongo"
	"log"
)

var (
	EXCHANGE_NAME     = "a-relationshipExchange"
	WORKER_QUEUE_NAME = "relationshipEventWorker"
)

type Consumer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

func main() {
	log.Println("Neo4J Feeder worker started")
	startConsuming()
	//looooop forever
	select {}
}

func startConsuming() {

	c := &Consumer{
		conn:    nil,
		channel: nil,
	}

	c.conn = amqputil.CreateConnection("neo4jFeeding")
	c.channel = amqputil.CreateChannel(c.conn)

	err := c.channel.ExchangeDeclare(EXCHANGE_NAME, "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	//name, durable, autoDelete, exclusive, noWait, args Table
	if _, err := c.channel.QueueDeclare(
		WORKER_QUEUE_NAME, true, false, false, false, nil
	); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind(WORKER_QUEUE_NAME, "" /* binding key */, EXCHANGE_NAME, false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	//(queue, consumer string, autoAck, exclusive, noLocal, noWait bool, args Table) (<-chan Delivery, error) {
	relationshipEvent, err := c.channel.Consume("relationshipEventWorker", "neo4jFeeding", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	go func() {
		for msg := range relationshipEvent {
			fmt.Println(msg)
			log.Printf("got %dB message data: [%v]-[%s] %s",
				len(msg.Body),
				msg.DeliveryTag,
				msg.RoutingKey,
				msg.Body)
			sa := mongo.createUniqueNode("hebe", "dede")
		}
	}()
}
