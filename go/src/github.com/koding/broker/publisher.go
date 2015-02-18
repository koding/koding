package broker

import (
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

func (b *Broker) NewPublisher() (Publisher, error) {
	producer := &Producer{
		ExchangeName: b.config.ExchangeName,
		Tag:          b.config.Tag,
		RoutingKey:   b.config.RoutingKey,
		Metrics:      b.Metrics,
	}

	// for now, use amqp publisher
	publisher, err := producer.createAMQPPublisher(b.MQ)
	if err != nil {
		return nil, err
	}

	// we created publisher successfully
	producer.Publisher = publisher
	return producer, nil

}

type Producer struct {
	Publisher    *rabbitmq.Producer
	ExchangeName string
	Tag          string
	RoutingKey   string
	Log          logging.Logger
	Metrics      *metrics.Metrics
}

// Publish, dispatches given message to the system, implements Publisher
// interface
func (p *Producer) Publish(messageType string, body []byte) error {
	if p.Publisher == nil {
		return ErrProducerNotInitialized
	}

	data := amqp.Publishing{
		Body: body,
		Type: messageType,
	}

	return p.Publisher.Publish(data)
}

// Close closes the publisher connection gracefully, implements Closer interface
func (p *Producer) Close() error {
	if p.Publisher != nil {
		return p.Publisher.Shutdown()
	}

	return nil
}

// createAMQPPublisher creates an AMQPPublisher
func (p *Producer) createAMQPPublisher(mq *rabbitmq.RabbitMQ) (*rabbitmq.Producer, error) {
	// create connection properties
	exchange := rabbitmq.Exchange{
		Name: p.ExchangeName,
	}

	publishingOptions := rabbitmq.PublishingOptions{
		Tag:        p.Tag,
		RoutingKey: p.RoutingKey,
		Immediate:  false,
	}

	return mq.NewProducer(
		exchange,
		rabbitmq.Queue{},
		publishingOptions,
	)
}
