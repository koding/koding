package rabbitmq

import (
	"errors"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"github.com/koding/logging"

	"github.com/streadway/amqp"
)

type Config struct {
	Host     string
	Port     int
	Username string
	Password string
	Vhost    string
}

func New(c *Config, log logging.Logger) *RabbitMQ {
	return &RabbitMQ{
		config: c,
		log:    log,
	}
}

type RabbitMQ struct {
	// The connection between client and the server
	conn *amqp.Connection

	// The communication channel over connection
	channel *amqp.Channel

	// Client's tag for current connection
	tag string

	// config stores the current koding configuration based on the given profile
	config *Config

	// logger interface
	log logging.Logger
}

type Exchange struct {
	// Exchange name
	Name string

	// Exchange type
	Type string

	// Durable exchanges will survive server restarts
	Durable bool

	// Will remain declared when there are no remaining bindings.
	AutoDelete bool

	// Exchanges declared as `internal` do not accept accept publishings.Internal
	// exchanges are useful for when you wish to implement inter-exchange topologies
	// that should not be exposed to users of the broker.
	Internal bool

	// When noWait is true, declare without waiting for a confirmation from the server.
	NoWait bool

	// amqp.Table of arguments that are specific to the server's implementation of
	// the exchange can be sent for exchange types that require extra parameters.
	Args amqp.Table
}

type Queue struct {
	// The queue name may be empty, in which the server will generate a unique name
	// which will be returned in the Name field of Queue struct.
	Name string

	// Check Exchange comments for durable
	Durable bool

	// Check Exchange comments for autodelete
	AutoDelete bool

	// Exclusive queues are only accessible by the connection that declares them and
	// will be deleted when the connection closes.  Channels on other connections
	// will receive an error when attempting declare, bind, consume, purge or delete a
	// queue with the same name.
	Exclusive bool

	// When noWait is true, the queue will assume to be declared on the server.  A
	// channel exception will arrive if the conditions are met for existing queues
	// or attempting to modify an existing queue from a different connection.
	NoWait bool

	// Check Exchange comments for Args
	Args amqp.Table
}

type ConsumerOptions struct {
	// The consumer is identified by a string that is unique and scoped for all
	// consumers on this channel.
	Tag string

	// When autoAck (also known as noAck) is true, the server will acknowledge
	// deliveries to this consumer prior to writing the delivery to the network.  When
	// autoAck is true, the consumer should not call Delivery.Ack
	AutoAck bool // autoAck

	// Check Queue struct documentation
	Exclusive bool // exclusive

	// When noLocal is true, the server will not deliver publishing sent from the same
	// connection to this consumer. (Do not use Publish and Consume from same channel)
	NoLocal bool // noLocal

	// Check Queue struct documentation
	NoWait bool // noWait

	// Check Exchange comments for Args
	Args amqp.Table // arguments
}

type BindingOptions struct {
	// Publishings messages to given Queue with matching -RoutingKey-
	// Every Queue has a default binding to Default Exchange with their Qeueu name
	// So you can send messages to a queue over default exchange
	RoutingKey string

	// Do not wait for a consumer
	NoWait bool

	// App specific data
	Args amqp.Table
}

// Returns RMQ connection
func (r *RabbitMQ) Conn() *amqp.Connection {
	return r.conn
}

// Controls how many messages the server will try to keep on
// the network for consumers before receiving delivery acks.  The intent of Qos is
// to make sure the network buffers stay full between the server and client.
func (r *RabbitMQ) QOS(messageCount int) error {
	return r.channel.Qos(messageCount, 0, false)
}

// newRabbitMQConnection opens a connection and a channel to RabbitMq
// In order to prevent developers from misconfiguration
// and using same channel for publishing and consuming it opens a new channel for
// every connection
// TODO this should not return RabbitMQ struct - cihangir,arslan config changes
func (r *RabbitMQ) Connect(tag string) (*RabbitMQ, error) {
	if tag == "" {
		return nil, errors.New("Tag is not defined in consumer options")
	}
	r.tag = tag
	conf := amqp.URI{
		Scheme:   "amqp",
		Host:     r.config.Host,
		Port:     r.config.Port,
		Username: r.config.Username,
		Password: r.config.Password,
		Vhost:    r.config.Vhost,
	}.String()

	var err error
	// get connection
	// Connects opens an AMQP connection from the credentials in the URL.
	r.conn, err = amqp.Dial(conf)
	if err != nil {
		return nil, err
	}

	r.handleErrors(r.conn)
	// getting channel
	r.channel, err = r.conn.Channel()
	if err != nil {
		return nil, err
	}

	return r, nil
}

// Session is holding the current Exchange, Queue,
// Binding Consuming and Publishing settings for enclosed
// rabbitmq connection
type Session struct {
	// Exchange declaration settings
	Exchange Exchange

	// Queue declaration settings
	Queue Queue

	// Binding options for current exchange to queue binding
	BindingOptions BindingOptions

	// Consumer options for a queue or exchange
	ConsumerOptions ConsumerOptions

	// Publishing options for a queue or exchange
	PublishingOptions PublishingOptions
}

// NotifyClose registers a listener for close events either initiated by an error
// accompaning a connection.close method or by a normal shutdown.
// On normal shutdowns, the chan will be closed.
// To reconnect after a transport or protocol error, we should register a listener here and
// re-connect to server
// Reconnection is -not- working by now
func (r *RabbitMQ) handleErrors(conn *amqp.Connection) {
	go func() {
		for amqpErr := range conn.NotifyClose(make(chan *amqp.Error)) {
			// if the computer sleeps then wakes longer than a heartbeat interval,
			// the connection will be closed by the client.
			// https://github.com/streadway/amqp/issues/82
			r.log.Fatal(amqpErr.Error())

			if strings.Contains(amqpErr.Error(), "NOT_FOUND") {
				// do not continue
			}

			// CRITICAL Exception (320) Reason: "CONNECTION_FORCED - broker forced connection closure with reason 'shutdown'"
			// CRITICAL Exception (501) Reason: "read tcp 127.0.0.1:5672: i/o timeout"
			// CRITICAL Exception (503) Reason: "COMMAND_INVALID - unimplemented method"
			if amqpErr.Code == 501 {
				// reconnect
			}

			if amqpErr.Code == 320 {
				// fmt.Println("tryin to reconnect")
				// c.reconnect()
			}

		}
	}()
	go func() {
		for b := range conn.NotifyBlocked(make(chan amqp.Blocking)) {
			if b.Active {
				r.log.Info("TCP blocked: %q", b.Reason)
			} else {
				r.log.Info("TCP unblocked")
			}
		}
	}()
}

// reconnect re-connects to rabbitmq after a disconnection
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

// Closer interface is for handling reconnection logic in a sane way
// Every reconnection supported struct should implement those methods
// in order to work properly
type Closer interface {
	RegisterSignalHandler()
	Shutdown() error
}

// shutdown is a general closer function for handling close gracefully
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

// registerSignalHandler helper function for stopping consumer or producer from
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
