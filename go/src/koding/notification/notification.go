package main

import (
	"encoding/json"
	"github.com/streadway/amqp"
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

type JoinMsg struct {
	RoutingKey string `json:"routingKey"`
	Username   string `json:"username"`
}

type LeaveMsg struct {
	RoutingKey string `json:"routingKey"`
}

var authPairs map[string]string
var producer *Producer

func main() {
	log.Println("notification worker started")

	authPairs = make(map[string]string)

	var err error
	producer, err = createProducer()
	if err != nil {
		log.Println(err)
	}

	startRouting()

	select {}
}

func startRouting() {
	c := &Consumer{
		conn:    nil,
		channel: nil,
		tag:     "",
	}

	var err error

	log.Printf("creating consumer connections")
	c.conn = amqputil.CreateConnection("notification")
	c.channel = amqputil.CreateChannel(c.conn)

	err = c.channel.ExchangeDeclare("notification-control", "fanout", false, true, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	err = c.channel.ExchangeDeclare("notification", "topic", false, true, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	if _, err := c.channel.QueueDeclare("authWorker", false, true, false, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind("authWorker", "", "notification-control", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	authStream, err := c.channel.Consume("authWorker", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	log.Println("routing started...")
	go func() {
		for msg := range authStream {
			log.Printf("got %dB message data: [%v]-[%s] %s",
				len(msg.Body),
				msg.DeliveryTag,
				msg.RoutingKey,
				msg.Body)

			switch msg.RoutingKey {
			case "auth.join":
				var join JoinMsg
				err := json.Unmarshal(msg.Body, &join)
				if err != nil {
					log.Print("bad json incoming msg: ", err)
				}

				authPairs[join.RoutingKey] = join.Username

				log.Println("Auth pairs:", authPairs) // this is just for debug

				go consumeFromUser(c, join.Username, join.RoutingKey)
			case "auth.leave":
				var leave LeaveMsg
				err := json.Unmarshal(msg.Body, &leave)
				if err != nil {
					log.Print("bad json incoming msg: ", err)
				}

				// delete user from the authPairs map and cancel it from consuming
				delete(authPairs, leave.RoutingKey)

				err = c.channel.Cancel(authPairs[leave.RoutingKey], false)
				if err != nil {
					log.Fatal("basic.cancel: %s", err)
				}

				log.Println("Auth pairs:", authPairs) // this is just for debug
			default:
				log.Println("routing key is not defined: ", msg.RoutingKey)
			}
		}

	}()

}

func consumeFromUser(c *Consumer, username, routingKey string) {
	if _, err := c.channel.QueueDeclare("", false, true, true, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind("", username, "notification", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	messages, err := c.channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	for msg := range messages {
		log.Printf("messages stream got %dB message data: [%v] %s",
			len(msg.Body),
			msg.DeliveryTag,
			msg.Body)

		publishToBroker(msg.Body, routingKey)
	}

}

func publishToBroker(data []byte, routingKey string) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	log.Println("publishing data ", string(data))
	err := producer.channel.Publish("broker", routingKey, false, false, msg)
	if err != nil {
		log.Printf("error while publishing proxy message: %s", err)
	}

}

func createProducer() (*Producer, error) {
	p := &Producer{
		conn:    nil,
		channel: nil,
	}

	log.Printf("creating publisher connections")

	p.conn = amqputil.CreateConnection("deneme")
	p.channel = amqputil.CreateChannel(p.conn)

	return p, nil
}
