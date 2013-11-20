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

// Durable    :
// 		Durable exchanges will survive server restarts and
// AutoDelete :
// 		Will remain declared when there are no remaining bindings.
// Internal   :
// 		Exchanges declared as `internal` do not accept accept publishings.Internal
// 		exchanges are useful for when you wish to implement inter-exchange topologies
// 		that should not be exposed to users of the broker.
// NoWait     :
// 		When noWait is true, declare without waiting for a confirmation from the server.
// Args :
// 		amqp.Table of arguments that are specific to the server's implementation of
// 		the exchange can be sent for exchange types that require extra parameters.
type Exchange struct {
	Name                                  string
	Type                                  string
	Durable, AutoDelete, Internal, NoWait bool
	Args                                  amqp.Table
}

// Name :
// 		The queue name may be empty, in which the server will generate a unique name
// 		which will be returned in the Name field of Queue struct.
// Durable-AutoDelete-Args:
// 		Check Exchange comments for those 3 fields
// Exclusive :
// 		Exclusive queues are only accessible by the connection that declares them and
// 		will be deleted when the connection closes.  Channels on other connections
// 		will receive an error when attempting declare, bind, consume, purge or delete a
// 		queue with the same name.
// NoWait :
// 		When noWait is true, the queue will assume to be declared on the server.  A
// 		channel exception will arrive if the conditions are met for existing queues
// 		or attempting to modify an existing queue from a different connection.
type Queue struct {
	Name                                   string
	Durable, AutoDelete, Exclusive, NoWait bool
	Args                                   amqp.Table
}

// Tag:
// 		The consumer is identified by a string that is unique and scoped for all
// 		consumers on this channel.
// AutoAck :
// 		When autoAck (also known as noAck) is true, the server will acknowledge
// 		deliveries to this consumer prior to writing the delivery to the network.  When
// 		autoAck is true, the consumer should not call Delivery.Ack
// Exclusive-NoWait-Args:
// 		Check Queue struct documentation
// NoLocal :
//		When noLocal is true, the server will not deliver publishing sent from the same
//		connection to this consumer. (Do not use Publish and Consume from same channel)
type ConsumerOptions struct {
	Tag       string     // consumerTag,
	AutoAck   bool       // autoAck
	Exclusive bool       // exclusive
	NoLocal   bool       // noLocal
	NoWait    bool       // noWait
	Args      amqp.Table // arguments
}

// Publishings messages to given Queue with matching -RoutingKey-
// Every Queue has a default binding to Default Exchange with their Qeueu name
// So you can send messages to a queue over default exchange
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

// Controls how many messages the server will try to keep on
// the network for consumers before receiving delivery acks.  The intent of Qos is
// to make sure the network buffers stay full between the server and client.
func (r *RabbitMQ) QOS(messageCount int) error {
	return r.channel.Qos(messageCount, 0, false)
}

// Opens a connection and a channel to RabbitMq
// In order to prevent developers from misconfiguration
// And using same channel for publishing and consuming
func newRabbitMQConnection(tag string) (*RabbitMQ, error) {

	if tag == "" {
		return nil, errors.New("Tag is not defined in consumer options")
	}

	rmq := &RabbitMQ{}

	rmq.tag = tag

	var err error

	// get connection
	// Connects opens an AMQP connection from the credentials in the URL.
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

// NotifyClose registers a listener for close events either initiated by an error
// accompaning a connection.close method or by a normal shutdown.
// On normal shutdowns, the chan will be closed.
// To reconnect after a transport or protocol error, we should register a listener here and
// re-connect to server
// Reconnection is -not- working by now
func handleErrors(conn *amqp.Connection) {
	go func() {
		for amqpErr := range conn.NotifyClose(make(chan *amqp.Error)) {
			// if the computer sleeps then wakes longer than a heartbeat interval,
			// the connection will be closed by the client.
			// https://github.com/streadway/amqp/issues/82
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
	// Commenting out this for now, since our package is not up-to-date
	// and the extension is not enabled yet in prodcution
	// We should also update our go amqp package
	// go func() {
	// 	for b := range conn.NotifyBlocked(make(chan amqp.Blocking)) {
	// 		if b.Active {
	// 			fmt.Println("TCP blocked: %q", b.Reason)
	// 		} else {
	// 			fmt.Println("TCP unblocked")
	// 		}
	// 	}
	// }()
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

// A general closer function for handling close gracefully
// Mostly here for both consumers and producers
// After a reconnection scenerio we are gonna call shutdown before connection
func shutdown(conn *amqp.Connection, channel *amqp.Channel, tag string) error {
	// This waits for a server acknowledgment which means the sockets will have
	// flushed all outbound publishings prior to returning.  It's important to
	// block on Close to not lose any publishings.
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

// helper function for stopping consumer or producer from
// operating further
// Watchs for SIGINT, SIGTERM, SIGQUIT, SIGSTOP and closes connection
func registerSignalHandler(c Closer) {
	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			signal := <-signals
			switch signal {
			case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP:
				err := c.Shutdown()
				if err != nil {
					panic(err)
				}
				os.Exit(1)
			}
		}
	}()
}
