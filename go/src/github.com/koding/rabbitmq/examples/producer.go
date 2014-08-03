package main

import (
	"fmt"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

func main() {
	rmq := rabbitmq.New(
		&rabbitmq.Config{
			Host:     "localhost",
			Port:     5672,
			Username: "guest",
			Password: "guest",
			Vhost:    "/",
		},
		logging.NewLogger("producer"),
	)

	exchange := rabbitmq.Exchange{
		Name: "EXCHANGE_NAME",
	}

	queue := rabbitmq.Queue{}
	publishingOptions := rabbitmq.PublishingOptions{
		Tag:        "ProducerTagHede",
		RoutingKey: "naber",
	}

	publisher, err := rmq.NewProducer(exchange, queue, publishingOptions)
	if err != nil {
		panic(err)
	}
	defer publisher.Shutdown()
	publisher.RegisterSignalHandler()

	// may be we should autoconvert to byte array?
	msg := amqp.Publishing{
		Body: []byte("2"),
	}

	publisher.NotifyReturn(func(message amqp.Return) {
		fmt.Println(message)
	})

	for i := 0; i < 10; i++ {
		err = publisher.Publish(msg)
		if err != nil {
			fmt.Println(err, i)
		}
	}
}
