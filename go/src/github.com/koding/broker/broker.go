package broker

import (
	"github.com/koding/logging"
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
	RoutingKey   string
	// broker tag for MQ connection
	Tag string
}

type Broker struct {
	mq       *rabbitmq.RabbitMQ
	log      logging.Logger
	config   *Config
	Producer *rabbitmq.Producer
	AppName  string
}

func New(appName string, c *Config, l logging.Logger) *Broker {
	// set defaults
	if c.ExchangeName == "" {
		c.ExchangeName = "BrokerMessageBus"
	}

	if c.Tag == "" {
		c.Tag = "BrokerMessageBusProducer"
	}

	return &Broker{
		mq:      rabbitmq.New(c.RMQConfig, l),
		log:     l,
		config:  c,
		AppName: appName,
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

	// b.Producer.NotifyReturn(func(message amqp.Return) {
	// 	fmt.Println(message)
	// })

	return nil
}

func (b *Broker) Close() error {
	if b.Producer == nil {
		return errors.New("Broker is not open, you cannot close it")
	}
	return b.Producer.Shutdown()
}

func (b *Broker) Publish(messageType string, body []byte) error {
	if b.Producer == nil {
		return MesssageBusNotInitializedErr
	}

	msg := amqp.Publishing{
		Body: body,
		Type: messageType,
	}

	return b.Producer.Publish(msg)
}
