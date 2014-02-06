package topicmodifier

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/messaging/rabbitmq"
)

type PublisherConfig struct {
	ExchangeName string
	Tag          string
	RoutingKey   string
}

func createPublisher(options *PublisherConfig) *rabbitmq.Producer {
	exchange := rabbitmq.Exchange{
		Name: options.ExchangeName,
	}
	queue := rabbitmq.Queue{}
	publishingOptions := rabbitmq.PublishingOptions{
		Tag:        options.Tag,
		RoutingKey: options.RoutingKey,
	}

	r := rabbitmq.New(Conf)
	producer, err := r.NewProducer(exchange, queue, publishingOptions)
	if err != nil {
		panic(err)
	}

	return producer
}

func publish(producer *rabbitmq.Producer, data interface{}) error {
	neoMessage, err := json.Marshal(data)
	if err != nil {
		log.Error("marshall error - %v", err)
		return err
	}

	message := amqp.Publishing{
		Body: neoMessage,
	}

	producer.NotifyReturn(func(message amqp.Return) {
		log.Info("%v", message)
	})

	return producer.Publish(message)
}
