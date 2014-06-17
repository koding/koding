package worker

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/koding/logging"
	"labix.org/v2/mgo"

	"github.com/jinzhu/gorm"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Listener struct {
	Consumer             *rabbitmq.Consumer
	MaintenancePublisher *rabbitmq.Producer
	SourceExchangeName   string
	WorkerName           string
	Log                  logging.Logger
}

func NewListener(workerName string, sourceExchangeName string, log logging.Logger) *Listener {
	return &Listener{
		WorkerName:         workerName,
		SourceExchangeName: sourceExchangeName,
		Log:                log,
	}
}

func (l *Listener) createConsumer(rmq *rabbitmq.RabbitMQ) *rabbitmq.Consumer {
	exchange := rabbitmq.Exchange{
		Name:    l.SourceExchangeName,
		Type:    "fanout",
		Durable: true,
	}

	queue := rabbitmq.Queue{
		Name:    fmt.Sprintf("%s:WorkerQueue", l.WorkerName),
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

	return Consumer
}

func (l *Listener) createMaintenancePublisher(rmq *rabbitmq.RabbitMQ) *rabbitmq.Producer {
	exchange := rabbitmq.Exchange{
		Name: "",
	}

	publishingOptions := rabbitmq.PublishingOptions{
		Tag:       fmt.Sprintf("%sWorkerConsumer", l.WorkerName),
		Immediate: false,
		// RoutingKey: "ApiMaintenanceQueue", // publish to ApiMaintenanceQueue
	}

	producer, err := rmq.NewProducer(
		exchange,
		rabbitmq.Queue{
			Name:    "ApiMaintenanceQueue",
			Durable: true,
		},
		publishingOptions,
	)
	if err != nil {
		panic(err)
	}

	return producer
}

func (l *Listener) Listen(rmq *rabbitmq.RabbitMQ, handler Handler) {
	// set consumer
	l.Consumer = l.createConsumer(rmq)
	l.MaintenancePublisher = l.createMaintenancePublisher(rmq)

	if err := l.Consumer.QOS(10); err != nil {
		panic(err)
	}

	l.Consumer.Consume(l.Start(handler))
}

func (l *Listener) Close() {
	l.Consumer.Shutdown()
	l.MaintenancePublisher.Shutdown()
}

var HandlerNotFoundErr = errors.New("Handler Not Found")

type Handler interface {
	HandleEvent(string, []byte) error
	ErrHandler
}

type ErrHandler interface {
	// bool is whether publishing the message to maintenance qeueue or not
	DefaultErrHandler(amqp.Delivery, error) bool
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
		case mgo.ErrNotFound:
			l.Log.Warning("Record not found in our mongo db (%s) recieved, deleting message from RMQ", string(delivery.Body))
			delivery.Ack(false)
		default:
			if handler.DefaultErrHandler(delivery, err) {
				data, err := json.Marshal(delivery)
				if err == nil {
					msg := amqp.Publishing{
						Body:  []byte(data),
						AppId: l.WorkerName,
					}
					l.MaintenancePublisher.Publish(msg)
				}
			}
		}
	}
}
