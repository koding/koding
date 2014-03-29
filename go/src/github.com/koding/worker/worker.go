package worker

import (
	"fmt"

	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Listener struct {
	Consumer           *rabbitmq.Consumer
	SourceExchangeName string
	WorkerName         string
}

func NewListener(workerName string, sourceExchangeName string) *Listener {
	return &Listener{
		WorkerName:         workerName,
		SourceExchangeName: sourceExchangeName,
	}
}

func (l *Listener) Listen(rmq *rabbitmq.RabbitMQ, startHandler func() func(delivery amqp.Delivery)) {
	exchange := rabbitmq.Exchange{
		Name:    l.SourceExchangeName,
		Type:    "fanout",
		Durable: true,
	}

	queue := rabbitmq.Queue{
		Name:    fmt.Sprintf("%sWorkerQueue", l.WorkerName),
		Durable: true,
	}

	binding := rabbitmq.BindingOptions{
		RoutingKey: "",
	}

	consumerOptions := rabbitmq.ConsumerOptions{
		Tag: fmt.Sprintf("%sWorkerConsumer", l.WorkerName),
	}

	Consumer, err := rmq.NewConsumer(exchange, queue, binding, consumerOptions)
	if err != nil {
		panic(err)
	}

	// set consumer
	l.Consumer = Consumer

	err = l.Consumer.QOS(10)
	if err != nil {
		panic(err)
	}

	l.Consumer.RegisterSignalHandler()
	l.Consumer.Consume(startHandler())
}

func (l *Listener) Close() {
	l.Consumer.Shutdown()
}
