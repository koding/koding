package helper

import (
	"github.com/streadway/amqp"
	"io/ioutil"
	"koding/tools/config"
	"log"
	"os"
	"strings"
)

type Producer struct {
	Conn    *amqp.Connection
	Channel *amqp.Channel
	Name    string
	Done    chan error
}

func NewProducer(name string) *Producer {
	return &Producer{
		Conn:    nil,
		Channel: nil,
		Name:    name,
		Done:    make(chan error),
	}
}

func CreateAmqpConnection() *amqp.Connection {
	user := config.Current.Kontrold.RabbitMq.Login
	password := config.Current.Kontrold.RabbitMq.Password
	host := config.Current.Kontrold.RabbitMq.Host
	port := config.Current.Kontrold.RabbitMq.Port

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

func CreateProducer(name string) (*Producer, error) {
	p := NewProducer(name)
	log.Printf("creating connection for sending %s messages", p.Name)
	p.Conn = CreateAmqpConnection()
	p.Channel = CreateChannel(p.Conn)

	return p, nil
}
