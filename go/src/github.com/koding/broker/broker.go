package broker

import (
	"fmt"

	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/rabbitmq"
)

type Closer interface {
	Close() error
}

type Publisher interface {
	Publish(messageType string, body []byte) error
	Closer
}

type Subscriber interface {
	Subscribe(messageType string, handler *SubscriptionHandler) error
	Listen() error
	SetContext(context ErrHandler) error
	Closer
}

type Config struct {
	// RMQ config
	RMQConfig *rabbitmq.Config

	// Publishing Config
	ExchangeName string

	// routing key for publishing events
	RoutingKey string

	// broker tag for MQ connection
	Tag string

	// Enable Maintenance Queue, if this is enabled, redelivered messages will
	// be put to maintenance queue
	EnableMaintenanceQueue bool
}

type Broker struct {
	// app's name which is using the broker
	AppName string
	// config for starting broker
	config *Config

	// broker has rabbitmq dependency for now
	mq *rabbitmq.RabbitMQ

	// logging
	log logging.Logger

	// for publishing events to the system
	Pub Publisher

	// for listening events in the system
	Sub Subscriber

	// metric about the broker
	Metrics *metrics.Metrics
}

// New creates a new broker instance
func New(appName string, c *Config, l logging.Logger) *Broker {
	// set defaults
	if c.ExchangeName == "" {
		c.ExchangeName = "BrokerMessageBus"
	}

	if c.Tag == "" {
		c.Tag = "BrokerMessageBusProducer"
	}

	// init broker
	return &Broker{
		mq:      rabbitmq.New(c.RMQConfig, l),
		log:     l,
		config:  c,
		AppName: appName,
	}

}

// Connect opens connections to prducer and consumer
func (b *Broker) Connect() error {
	producer, err := b.NewPublisher()
	if err != nil {
		return err
	}

	b.log.Info("connected to producer %s", "ok")
	b.Pub = producer

	subscriber, err := b.NewSubscriber()
	if err != nil {
		return err
	}

	b.log.Info("connected to subscriber %s", "ok")
	b.Sub = subscriber

	return nil
}

// Close, shutdowns all connections
func (b *Broker) Close() error {
	var err, err2 error
	if b.Pub != nil {
		err = b.Pub.Close()
	}
	b.log.Info("Publisher closed %t", err == nil)

	if b.Sub != nil {
		// i could return the result of b.Sub.Close here, but this can lead a
		// misconception about closing other connections which are added after
		// this line
		err2 = b.Sub.Close()
	}

	b.log.Info("Subscriber closed %t", err2 == nil)

	if err == nil && err2 == nil {
		return nil
	}

	return fmt.Errorf(
		"got error while closing conns: PubErr: %s, SubErr: %s",
		err.Error(),
		err2.Error(),
	)
}

func (b *Broker) Publish(messageType string, body []byte) error {
	if b.Pub == nil {
		return ErrProducerNotInitialized
	}

	return b.Pub.Publish(messageType, body)
}

func (b *Broker) Subscribe(messageType string, handler interface{}) error {
	if b.Sub == nil {
		return ErrSubscriberNotInitialized
	}

	h, err := NewSubscriptionHandler(handler)
	if err != nil {
		return err
	}

	return b.Sub.Subscribe(messageType, h)
}

func (b *Broker) Listen() error {
	if b.Sub == nil {
		return ErrSubscriberNotInitialized
	}

	return b.Sub.Listen()
}

func (b *Broker) SetContext(context ErrHandler) error {
	if b.Sub == nil {
		return ErrSubscriberNotInitialized
	}

	return b.Sub.SetContext(context)
}
