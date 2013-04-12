package main

import (
	"github.com/streadway/amqp"
	"io/ioutil"
	"koding/tools/config"
	"log"
	"os"
	"strings"
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

	var err error

	appId := customHostname()

	user := config.Current.Kontrold.Login
	password := config.Current.Kontrold.Password
	host := config.Current.Kontrold.Host
	port := config.Current.Kontrold.Port

	url := "amqp://" + user + ":" + password + "@" + host + ":" + port
	c.conn, err = amqp.Dial(url)
	if err != nil {
		log.Fatal(err)
	}

	c.channel, err = c.conn.Channel()
	if err != nil {
		log.Fatal(err)
	}

	err = c.channel.ExchangeDeclare("infoExchange", "topic", true, false, false, false, nil)
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

func (a *AmqpStream) Publish(data []byte) {
	appId := customHostname()
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
		AppId:           appId,
	}

	a.channel.Publish("infoExchange", "input.proxy", false, false, msg)
}

func customHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		log.Println(err)
	}

	hostVersion := hostname + "-" + readVersion()
	return hostVersion
}

func readVersion() string {
	file, err := ioutil.ReadFile("VERSION")
	if err != nil {
		log.Println(err)
	}

	return strings.TrimSpace(string(file))
}
