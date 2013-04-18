package main

import (
	"encoding/json"
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

type Credential struct {
	Token    string `json:"token"`
	Username string `json:"username"`
}

var tokens map[string]string
var producer *Producer

func main() {
	log.Println("notification worker started")

	tokens = make(map[string]string)

	var err error
	producer, err = createProducer()
	if err != nil {
		log.Println(err)
	}

	startRouting()

	select {}
}

func startRouting() {
	log.Println("routing started")
	c := &Consumer{
		conn:    nil,
		channel: nil,
		tag:     "",
	}

	var err error
	user, password, host, port := getAmqpCredentials()

	type bind struct {
		queue string
		key   string
	}

	url := "amqp://" + user + ":" + password + "@" + host + ":" + port
	c.conn, err = amqp.Dial(url)
	if err != nil {
		log.Fatal(err)
	}

	c.channel, err = c.conn.Channel()
	if err != nil {
		log.Fatal(err)
	}

	err = c.channel.ExchangeDeclare("notification-control", "fanout", true, false, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	err = c.channel.ExchangeDeclare("notification", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	// consume from notification-control

	// declaring this queue will be removed and and the queue from authworker will be used
	if _, err := c.channel.QueueDeclare("authWorker", false, true, false, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind("authWorker", "", "notification-control", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	pairs, err := c.channel.Consume("authWorker", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	// start handling messages
	go func() {
		for pair := range pairs {
			log.Printf("token stream got %dB message data: [%v] %s",
				len(pair.Body),
				pair.DeliveryTag,
				pair.Body)

			var cred Credential
			err := json.Unmarshal(pair.Body, &cred)
			if err != nil {
				log.Print("bad json incoming msg: ", err)
			}

			tokens[cred.Username] = cred.Token

			go consumeFromUser(c, cred.Username)

		}

	}()

}

func consumeFromUser(c *Consumer, username string) {
	if _, err := c.channel.QueueDeclare(username, false, true, true, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind("", username, "notification", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	messages, err := c.channel.Consume(username, "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	for msg := range messages {
		log.Printf("messages stream got %dB message data: [%v] %s",
			len(msg.Body),
			msg.DeliveryTag,
			msg.Body)

		publishToBroker(msg.Body, tokens[username])
	}

}

func publishToBroker(data []byte, token string) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	log.Println("publishing data ", string(data))
	err := producer.channel.Publish("broker", token, false, false, msg)
	if err != nil {
		log.Printf("error while publishing proxy message: %s", err)
	}

}

func getAmqpCredentials() (string, string, string, string) {
	user := "guest"
	password := "guest"
	host := "localhost"
	port := "5672"

	return user, password, host, port
}

func createProducer() (*Producer, error) {
	p := &Producer{
		conn:    nil,
		channel: nil,
	}

	log.Printf("creating publisher connections")

	var err error
	user, password, host, port := getAmqpCredentials()

	url := "amqp://" + user + ":" + password + "@" + host + ":" + port
	p.conn, err = amqp.Dial(url)
	if err != nil {
		log.Fatal(err)
	}

	p.channel, err = p.conn.Channel()
	if err != nil {
		log.Fatal(err)
	}

	return p, nil
}
