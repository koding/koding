package worker

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"

	"github.com/jinzhu/gorm"
	"github.com/rcrowley/go-metrics"
	"github.com/streadway/amqp"
	"labix.org/v2/mgo"
)

type Listener struct {
	Consumer             *rabbitmq.Consumer
	MaintenancePublisher *rabbitmq.Producer
	SourceExchangeName   string
	WorkerName           string
	Log                  logging.Logger
	Metrics              *Metrics
}

type Metrics struct {
	Registry metrics.Registry
	*MetricsCounter
}

type MetricsCounter struct {
	Messages, Success, Handler404, Mgo404, Gorm404, OtherError metrics.Counter
}

func NewListener(workerName string, sourceExchangeName string, log logging.Logger) *Listener {
	return &Listener{
		WorkerName:         workerName,
		SourceExchangeName: sourceExchangeName,
		Log:                log,
		Metrics:            initializeMetrics(workerName),
	}
}

func initializeMetrics(name string) *Metrics {
	r := metrics.NewRegistry()

	messages := metrics.NewCounter()
	r.Register(name+"messages", messages)

	success := metrics.NewCounter()
	r.Register(name+"success", success)

	handler404 := metrics.NewCounter()
	r.Register(name+"handler404", success)

	mgo404 := metrics.NewCounter()
	r.Register(name+"mgo404", mgo404)

	gorm404 := metrics.NewCounter()
	r.Register(name+"gorm404", gorm404)

	otherError := metrics.NewCounter()
	r.Register(name+"otherError", otherError)

	return &Metrics{
		r,
		&MetricsCounter{
			Messages:   messages,
			Success:    success,
			Handler404: handler404,
			Mgo404:     mgo404,
			Gorm404:    gorm404,
			OtherError: otherError,
		},
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
		l.Metrics.Messages.Inc(1)

		err := handler.HandleEvent(delivery.Type, delivery.Body)
		switch err {
		case nil:
			l.Metrics.Success.Inc(1)
			delivery.Ack(false)
		case HandlerNotFoundErr:
			l.Metrics.Handler404.Inc(1)
			l.Log.Debug("unknown event type (%s) recieved, deleting message from RMQ", delivery.Type)

			delivery.Ack(false)
		case gorm.RecordNotFound:
			l.Metrics.Gorm404.Inc(1)
			l.Log.Warning("Record not found in our db (%s) recieved, deleting message from RMQ", string(delivery.Body))

			delivery.Ack(false)
		case mgo.ErrNotFound:
			l.Metrics.Mgo404.Inc(1)
			l.Log.Warning("Record not found in our mongo db (%s) recieved, deleting message from RMQ", string(delivery.Body))

			delivery.Ack(false)
		default:
			l.OtherError.Mgo404.Inc(1)

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
