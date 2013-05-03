package helper

import (
	"github.com/streadway/amqp"
	"io/ioutil"
	"log"
	"os"
	"strings"
)

func CreateAmqpConnection(user, password, host, port string) *amqp.Connection {
	if port == "" {
		port = "5672" // default RABBITMQ_NODE_PORT
	}

	url := "amqp://" + user + ":" + password + "@" + host + ":" + port
	conn, err := amqp.Dial(url)
	if err != nil {
		log.Fatalln("AMQP dial: ", err)
	}

	go func() {
		for err := range conn.NotifyClose(make(chan *amqp.Error)) {
			log.Fatalln("AMQP connection: " + err.Error())
		}
	}()

	return conn
}

func CreateChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		panic(err)
	}
	go func() {
		for err := range channel.NotifyClose(make(chan *amqp.Error)) {
			log.Fatalln("AMQP channel: " + err.Error())
		}
	}()
	return channel
}

func CustomHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		log.Println(err)
	}

	return hostname
}

func ReadVersion() string {
	file, err := ioutil.ReadFile("VERSION")
	if err != nil {
		log.Println(err)
	}

	return strings.TrimSpace(string(file))
}
