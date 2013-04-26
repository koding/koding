package main

import (
	"bufio"
	"bytes"
	"github.com/streadway/amqp"
	"log"
	"net/http"
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

func main() {
	log.Println("kontrol rabbitproxy started")

	var err error
	producer, err = createProducer()
	if err != nil {
		log.Println(err)
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

	if err := c.channel.QueueBind("", "local.key", "kontrol-rabbitproxy", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	httpStream, err := c.channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	log.Println("routing started...")
	for msg := range httpStream {
		log.Printf("got %dB message data: [%v]-[%s] %s",
			len(msg.Body),
			msg.DeliveryTag,
			msg.RoutingKey,
			msg.Body)
		switch msg.RoutingKey {
		case "local.key":
			body, err := doRequest(msg.Body)
			if err != nil {
				log.Println(err)
				go publishToRemote(nil, "remote.key")
			} else {
				go publishToRemote(body, "remote.key")
			}

		}
	}
}

func doRequest(msg []byte) ([]byte, error) {
	buf := bytes.NewBuffer(msg)
	reader := bufio.NewReader(buf)
	req, err := http.ReadRequest(reader)
	if err != nil {
		log.Println(err)
	}

	// Request.RequestURI can't be set in client requests.
	// http://golang.org/src/pkg/net/http/client.go
	req.RequestURI = ""

	log.Println("Doing a http request")
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}

	output := new(bytes.Buffer)
	resp.Write(output)
	data := output.Bytes()

	log.Println("Response is", string(data))

	return data, nil
}

func publishToRemote(data []byte, routingKey string) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	log.Println("publishing data ", string(data), routingKey)
	err := producer.channel.Publish("kontrol-rabbitproxy", routingKey, false, false, msg)
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
	var err error
	user := "guest"
	password := "guest"
	host := "localhost"
	port := "5672"

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
