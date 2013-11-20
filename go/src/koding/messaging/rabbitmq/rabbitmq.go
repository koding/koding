package rabbitmq

import (
	"errors"
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/config"
	"os"
	"os/signal"
	"strings"
	"syscall"
)

type Exchange struct {
	Name                                  string
	Type                                  string
	Durable, AutoDelete, Internal, NoWait bool
	Args                                  amqp.Table
}

type Queue struct {
	Name                                   string
	Durable, AutoDelete, Exclusive, NoWait bool
	Args                                   amqp.Table
}

type ConsumerOptions struct {
	Tag       string     // consumerTag,
	AutoAck   bool       // autoAck
	Exclusive bool       // exclusive
	NoLocal   bool       // noLocal
	NoWait    bool       // noWait
	Args      amqp.Table // arguments
}

type BindingOptions struct {
	RoutingKey string
	NoWait     bool
	Args       amqp.Table
}

// type Table amqp.Table

func getConnectionString() string {
	return amqp.URI{
		Scheme:   "amqp",
		Host:     config.Current.Mq.Host,
		Port:     config.Current.Mq.Port,
		Username: config.Current.Mq.ComponentUser,
		Password: config.Current.Mq.Password,
		Vhost:    config.Current.Mq.Vhost,
	}.String()
}

type RabbitMQ struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	tag     string
}

func newRabbitMQ(tag string) (*RabbitMQ, error) {

	if tag == "" {
		return nil, errors.New("Tag is not defined in consumer options")
	}

	rmq := &RabbitMQ{}

	rmq.tag = tag

	var err error

	// get connection
	rmq.conn, err = amqp.Dial(getConnectionString())
	if err != nil {
		return nil, err
	}
	handleErrors(rmq.conn)
	// getting channel
	rmq.channel, err = rmq.conn.Channel()
	if err != nil {
		return nil, err
	}
	return rmq, nil
}

type Session struct {
	Exchange          Exchange
	Queue             Queue
	BindingOptions    BindingOptions
	ConsumerOptions   ConsumerOptions
	PublishingOptions PublishingOptions
}

func handleErrors(conn *amqp.Connection) {
	go func() {
		for amqpErr := range conn.NotifyClose(make(chan *amqp.Error)) {
			fmt.Println(amqpErr)

			if strings.Contains(amqpErr.Error(), "NOT_FOUND") {
				// do not continue
			}
			if amqpErr.Code == 501 {
				// reconnect
			}
			if amqpErr.Code == 320 {
				// fmt.Println("tryin to reconnect")
				// c.reconnect()
			}
		}
	}()
}

func (c *Consumer) reconnect() {

	err := c.Shutdown()
	if err != nil {
		panic(err)
	}
	err = c.connect()
	if err != nil {
		panic(err)
	}
	c.Consume(c.handler)
}

type Closer interface {
	RegisterSignalHandler()
	Shutdown() error
}

func shutdown(conn *amqp.Connection, channel *amqp.Channel, tag string) error {
	// will close() the channel
	if err := channel.Cancel(tag, true); err != nil {
		if amqpError, isAmqpError := err.(*amqp.Error); isAmqpError && amqpError.Code != 504 {
			return fmt.Errorf("AMQP connection close error: %s", err)
		}
	}

	if err := conn.Close(); err != nil {
		if amqpError, isAmqpError := err.(*amqp.Error); isAmqpError && amqpError.Code != 504 {
			return fmt.Errorf("AMQP connection close error: %s", err)
		}
	}

	return nil
}

func registerSignalHandler(c Closer) {
	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			signal := <-signals
			switch signal {
			case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGSTOP:
				err := c.Shutdown()
				if err != nil {
					panic(err)
				}
				os.Exit(1)
			}
		}
	}()
}
