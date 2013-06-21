package main

import (
	"crypto/rand"
	"encoding/base64"
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
	Name               string  `json:"name"`
	BindingExchange    string  `json:"bindingExchange"`
	BindingKey         string  `json:"bindingKey"`
	PublishingExchange *string `json:"publishingExchange"`
	RoutingKey         string  `json:"routingKey"`
	ConsumerTag        string
	Suffix             string `json:"suffix"`
}

type LeaveMsg struct {
	RoutingKey string `json:"routingKey"`
}

var authPairs map[string]JoinMsg
var exchanges map[string]uint
var producer *Producer

func main() {
	log.Println("routing worker started")

	authPairs = make(map[string]JoinMsg)
	exchanges = make(map[string]uint)

	var err error
	producer, err = createProducer()
	if err != nil {
		log.Printf("create producer: %v", err)
	}

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
		log.Printf("got %dB message data: [%v]-[%s] %s",
			len(msg.Body),
			msg.DeliveryTag,
			msg.RoutingKey,
			msg.Body,
		)

		switch msg.RoutingKey {
		case "auth.join":
			var join JoinMsg
			err := json.Unmarshal(msg.Body, &join)
			if err != nil {
				log.Print("bad json incoming msg: ", err)
			}

			var publishingExchange string
			if join.PublishingExchange != nil {
				publishingExchange = *join.PublishingExchange
			} else {
				publishingExchange = "broker"
			}

			join.ConsumerTag = generateUniqueConsumerTag(join.BindingKey)
			authPairs[join.RoutingKey] = join

			log.Println("Auth pairs:", authPairs) // this is just for debug

			declareExchange(c, join.BindingExchange)

			errors := make(chan error)

			go consumeAndRepublish(c,
				join.BindingExchange,
				join.BindingKey,
				publishingExchange,
				join.RoutingKey,
				join.Suffix,
				join.ConsumerTag,
				errors,
			)
			// select {
			// case errors <- err:
			// 	log.Printf("Handled an error: %v", err)
			// }
		case "auth.leave":
			var leave LeaveMsg
			err := json.Unmarshal(msg.Body, &leave)
			if err != nil {
				log.Print("bad json incoming msg: ", err)
			}

			// cancel consuming
			err = c.channel.Cancel(authPairs[leave.RoutingKey].ConsumerTag, false)
			if err != nil {
				log.Fatalf("basic.cancel: %s", err)
			}
			decrementExchangeCounter(leave)

		default:
			log.Println("routing key is not defined: ", msg.RoutingKey)
		}
	}
}

func generateUniqueConsumerTag(bindingKey string) string {
	r := make([]byte, 32/8)
	rand.Read(r)
	return bindingKey + "." + base64.StdEncoding.EncodeToString(r)
}

func generateUniqueQueueName() string {
	r := make([]byte, 32/8)
	rand.Read(r)
	return base64.StdEncoding.EncodeToString(r)
}

func declareExchange(c *Consumer, exchange string) {
	if exchanges[exchange] <= 0 {
		if err := c.channel.ExchangeDeclare(exchange, "topic", false, true, false, false, nil); err != nil {
			log.Fatalf("exchange.declare: %s", err)
		}
		exchanges[exchange] = 0
	}
	exchanges[exchange]++
}

func decrementExchangeCounter(leave LeaveMsg) {
	exchange := authPairs[leave.RoutingKey].BindingExchange
	// decrement exchange counter
	exchanges[exchange]--
	// delete authPairs map
	delete(authPairs, leave.RoutingKey)
}

func consumeAndRepublish(
	c *Consumer,
	bindingExchange,
	bindingKey,
	publishingExchange,
	routingKey,
	suffix,
	consumerTag string,
	done chan error,
) {
	log.Printf("Consume from:\n bindingExchange %s\n bindingKey %s\n routingKey %s\n consumerTag %s\n",
		bindingExchange, bindingKey, routingKey, consumerTag)

	if len(suffix) > 0 {
		routingKey += suffix
	}

	channel, err := c.conn.Channel()
	if err != nil {
		done <- err
		return
	}
	defer channel.Close()

	uniqueQueueName := generateUniqueQueueName()

	if _, err := channel.QueueDeclare(uniqueQueueName, false, true, true, false, nil); err != nil {
		log.Fatalf("queue.declare: %s", err)
	}

	if err := channel.QueueBind(uniqueQueueName, bindingKey, bindingExchange, false, nil); err != nil {
		log.Fatalf("queue.bind: %s", err)
	}

	messages, err := channel.Consume(uniqueQueueName, consumerTag, true, false, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	for msg := range messages {
		log.Printf("messages stream got %dB message data: [%v] %s",
			len(msg.Body),
			msg.DeliveryTag,
			msg.Body,
		)

		publishTo(publishingExchange, routingKey, msg.Body)
	}

}

func publishTo(exchange, routingKey string, data []byte) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	log.Println("publishing data ", exchange, string(data), routingKey)
	err := producer.channel.Publish(exchange, routingKey, false, false, msg)
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

	p.conn = amqputil.CreateConnection("routing")
	p.channel = amqputil.CreateChannel(p.conn)

	return p, nil
}
