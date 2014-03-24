package broker

import (
	"errors"
	"fmt"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Config struct {
	// RMQ config
	Host     string
	Port     int
	Username string
	Password string
	Vhost    string

	// Publishing Config
	ExchangeName string
	RoutingKey   string
	// broker tag for MQ connection
	Tag string
}

type Broker struct {
	mq       *rabbitmq.RabbitMQ
	log      logging.Logger
	config   *Config
	Producer *rabbitmq.Producer
}

func New(c *Config, l logging.Logger) *Broker {
	mqConfig := &rabbitmq.Config{
		Host:     c.Host,
		Port:     c.Port,
		Username: c.Username,
		Password: c.Password,
		Vhost:    c.Vhost,
	}

	// set defaults
	if c.ExchangeName == "" {
		c.ExchangeName = "BrokerMessageBus"
	}

	if c.Tag == "" {
		c.Tag = "BrokerMessageBusProducer"
	}

	return &Broker{
		mq:     rabbitmq.New(mqConfig, l),
		log:    l,
		config: c,
	}

}

var MesssageBusNotInitializedErr = errors.New("MessageBus not initialized")

func (b *Broker) Connect() error {
	exchange := rabbitmq.Exchange{
		Name: b.config.ExchangeName,
	}

	publishingOptions := rabbitmq.PublishingOptions{
		Tag:        b.config.Tag,
		RoutingKey: b.config.RoutingKey,
		Immediate:  false,
	}

	var err error
	b.Producer, err = b.mq.NewProducer(
		exchange,
		rabbitmq.Queue{},
		publishingOptions,
	)
	if err != nil {
		return err
	}

	b.Producer.RegisterSignalHandler()
	return nil
}

func (b *Broker) Close() error {
	return b.Producer.Shutdown()
}

func (b *Broker) Publish(messageType string, body []byte) error {
	fmt.Println("publish icide", messageType)
	fmt.Println("publish icide", b.Producer)
	if b.Producer == nil {
		return MesssageBusNotInitializedErr
	}

	msg := amqp.Publishing{
		Body: body,
		Type: messageType,
	}

	return b.Producer.Publish(msg)
}
