package eventbus

import (
	"errors"
	"fmt"
	"koding/messaging/rabbitmq"
	"koding/tools/config"
	socialconfig "socialapi/config"

	"github.com/streadway/amqp"
)

var MesageBus *rabbitmq.Producer
var MesssageBusNotInitializedErr = errors.New("MessageBus not initialized")

func Open(c *config.Config) error {
	rmq := rabbitmq.New(c)
	return initMessageBus(rmq)
}

func Close() {
	if MesageBus != nil {
		MesageBus.Shutdown()
	}
}

func initMessageBus(rmq *rabbitmq.RabbitMQ) error {
	exchangeName := socialconfig.EventExchangeName
	tag := "MessageBusPublisher"
	routingKey := ""

	exchange := rabbitmq.Exchange{
		Name: exchangeName,
	}

	publishingOptions := rabbitmq.PublishingOptions{
		Tag:        tag,
		RoutingKey: routingKey,
		Immediate:  false,
	}

	var err error
	MesageBus, err = rmq.NewProducer(
		exchange,
		rabbitmq.Queue{},
		publishingOptions,
	)
	if err != nil {
		return err
	}
	MesageBus.RegisterSignalHandler()

	MesageBus.NotifyReturn(func(message amqp.Return) {
		fmt.Println(fmt.Sprintf("Message is returned from RabitMQ %v", message))
	})
	return nil
}

func Publish(messageType string, body []byte) error {
	if MesageBus == nil {
		return MesssageBusNotInitializedErr
	}

	msg := amqp.Publishing{
		Body: body,
		Type: messageType,
	}

	return MesageBus.Publish(msg)
}
