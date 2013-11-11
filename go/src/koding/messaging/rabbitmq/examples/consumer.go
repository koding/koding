package main

import (
	"fmt"
	"github.com/streadway/amqp"
	"koding/messaging/rabbitmq"
)

func main() {
	exchange := rabbitmq.Exchange{
		Name:    "EXCHANGE_NAME",
		Type:    "fanout",
		Durable: true,
	}

	queue := rabbitmq.Queue{
		Name:    "WORKER_QUEUE_NAME",
		Durable: true,
	}
	binding := rabbitmq.BindingOptions{
		RoutingKey: "hede",
	}

	consumerOptions := rabbitmq.ConsumerOptions{
		Tag: "ElasticSearchFeeder",
	}

	consumer, err := rabbitmq.NewConsumer(exchange, queue, binding, consumerOptions)
	if err != nil {
		fmt.Print(err)
		return
	}
	defer consumer.Shutdown()

	fmt.Println("Elasticsearch Feeder worker started")
	consumer.RegisterSignalHandler()
	consumer.Consume(handler)

}

var handler = func(deliveries <-chan amqp.Delivery) {
	for msg := range deliveries {
		message := string(msg.Body)
		fmt.Println(message)
		msg.Ack(false)
	}
}
