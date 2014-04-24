package worker

import (
	"errors"
	"fmt"
	"github.com/koding/logging"

	"github.com/jinzhu/gorm"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Listener struct {
	Consumer           *rabbitmq.Consumer
	SourceExchangeName string
	WorkerName         string
	Log                logging.Logger
}

func NewListener(workerName string, sourceExchangeName string, log logging.Logger) *Listener {
	return &Listener{
		WorkerName:         workerName,
		SourceExchangeName: sourceExchangeName,
		Log:                log,
	}
}

func (l *Listener) Listen(rmq *rabbitmq.RabbitMQ, handler Handler) {
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
	l.Consumer.Consume(l.Start(handler))
}

func (l *Listener) Close() {
	l.Consumer.Shutdown()
}

var HandlerNotFoundErr = errors.New("Handler Not Found")

type Handler interface {
	HandleEvent(string, []byte) error
	DefaultErrHandler(amqp.Delivery, error)
}

func (l *Listener) Start(handler Handler) func(delivery amqp.Delivery) {
	l.Log.Info("Worker Started to Consume")
	return func(delivery amqp.Delivery) {
		err := handler.HandleEvent(delivery.Type, delivery.Body)
		switch err {
		case nil:
			delivery.Ack(false)
		case HandlerNotFoundErr:
			l.Log.Notice("unknown event type (%s) recieved, \n deleting message from RMQ", delivery.Type)
			delivery.Ack(false)
		case gorm.RecordNotFound:
			l.Log.Warning("Record not found in our db (%s) recieved, \n deleting message from RMQ", string(delivery.Body))
			delivery.Ack(false)
		default:
			// add proper error handling
			// instead of puttting message back to same queue, it is better
			// to put it to another maintenance queue/exchange
			l.Log.Error("an error occured %s, \n putting message back to queue", err)
			// // multiple false
			// // reque true
			// delivery.Nack(false, true)
		}
	}
}
