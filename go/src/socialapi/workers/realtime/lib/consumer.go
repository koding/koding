package realtime

import (
	"fmt"
	"socialapi/config"
	"github.com/koding/rabbitmq"

	"github.com/streadway/amqp"
)

var (
	Consumer        *rabbitmq.Consumer
	WorkerQueueName = "RealtimeWorkerQueue"
	WorkerQueueTag  = "RealtimeWorkerConsumer"
	RMQConnection   *amqp.Connection
)

func Listen(rmq *rabbitmq.RabbitMQ, startHandler func() func(delivery amqp.Delivery)) {
	// set rmq connection
	rmqConn, err := rmq.Connect("RealtimeWorker")
	if err != nil {
		panic(err)
	}

	RMQConnection = rmqConn.Conn()

	exchange := rabbitmq.Exchange{
		Name:    config.EventExchangeName,
		Type:    "fanout",
		Durable: true,
	}

	queue := rabbitmq.Queue{
		Name:    WorkerQueueName,
		Durable: true,
	}

	binding := rabbitmq.BindingOptions{
		RoutingKey: "",
	}

	consumerOptions := rabbitmq.ConsumerOptions{
		Tag: WorkerQueueTag,
	}

	Consumer, err := rmq.NewConsumer(exchange, queue, binding, consumerOptions)
	if err != nil {
		fmt.Print(err)
		return
	}

	err = Consumer.QOS(10)
	if err != nil {
		panic(err)
	}

	Consumer.RegisterSignalHandler()
	Consumer.Consume(startHandler())
}
