package topicmodifier

import (
	"encoding/json"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
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

	rmqConf := &rabbitmq.Config{
		Host:     Conf.Mq.Host,
		Port:     Conf.Mq.Port,
		Username: Conf.Mq.ComponentUser,
		Password: Conf.Mq.Password,
		Vhost:    Conf.Mq.Vhost,
	}
	r := rabbitmq.New(rmqConf, log)
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
