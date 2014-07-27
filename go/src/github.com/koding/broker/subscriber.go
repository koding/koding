package broker

import (
	"fmt"
	"reflect"
	"sync"

	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/rabbitmq"
)

// NewSubscriber creates a new subscriber
func (b *Broker) NewSubscriber() (Subscriber, error) {
	l := &Consumer{
		// tha app's name
		WorkerName: b.AppName,

		// which exchange will be listened
		SourceExchangeName: b.config.ExchangeName,

		// basic logger
		Log: b.log,

		// whether send or not redelivered items to the maintenance queue
		EnableMaintenanceQueue: b.config.EnableMaintenanceQueue,

		// gather metric into this property
		Metrics: b.Metrics,
	}

	// create the consumer
	consumer, err := l.createConsumer(b.mq)
	if err != nil {
		return nil, err
	}
	l.Consumer = consumer

	// set quality of the service
	// TODO get this from config
	if err := l.Consumer.QOS(10); err != nil {
		return nil, err
	}

	if b.config.EnableMaintenanceQueue {
		maintenanceQ, err := l.createMaintenancePublisher(b.mq)
		if err != nil {
			return nil, err
		}

		l.MaintenancePublisher = maintenanceQ
	}

	return l, nil
}

// Consumer is the consumer of all messages
type Consumer struct {
	// From which exhange the data will be consumed
	SourceExchangeName string

	// RMQ connection for consuming events
	Consumer *rabbitmq.Consumer

	// Maintenance Queue connection
	MaintenancePublisher *rabbitmq.Producer

	// Worker's name for consumer
	WorkerName string

	// logger
	Log logging.Logger

	// whether or not to send error-ed messages to the maintenance queue
	EnableMaintenanceQueue bool

	// Metrics about the broker
	Metrics *metrics.Metrics

	// context for subscriptions
	context      ErrHandler
	contextValue reflect.Value

	// all handlers which are listed
	handlers map[string][]*SubscriptionHandler
	// for handler registeration purposes
	sync.Mutex
}

// SetContext wraps the context for calling the handlers within given context
func (c *Consumer) SetContext(context ErrHandler) error {
	c.context = context
	c.contextValue = reflect.ValueOf(context)

	return nil
}

// Subscribe registers itself to a subscriber
func (l *Consumer) Subscribe(messageType string, handler *SubscriptionHandler) error {
	if l.Consumer == nil {
		return ErrSubscriberNotInitialized
	}

	l.Lock()
	defer l.Unlock()

	if l.handlers == nil {
		l.handlers = make(map[string][]*SubscriptionHandler)
	}

	if _, ok := l.handlers[messageType]; !ok {
		l.handlers[messageType] = make([]*SubscriptionHandler, 0)
	}

	l.handlers[messageType] = append(l.handlers[messageType], handler)

	return nil
}

// Close closes the connections gracefully
func (l *Consumer) Close() error {
	if l.Consumer != nil {
		if err := l.Consumer.Shutdown(); err != nil {
			return err
		}
	}

	if l.MaintenancePublisher != nil {
		if err := l.MaintenancePublisher.Shutdown(); err != nil {
			return err
		}
	}

	return nil
}

func (l *Consumer) Listen() error {
	if len(l.handlers) == 0 {
		return ErrNoHandlerFound
	}

	l.Consumer.Consume(l.Start())

	return nil
}

// createConsumer creates a new amqp consumer
func (l *Consumer) createConsumer(rmq *rabbitmq.RabbitMQ) (*rabbitmq.Consumer, error) {
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

	consumer, err := rmq.NewConsumer(exchange, queue, binding, consumerOptions)
	if err != nil {
		return nil, err
	}

	return consumer, nil
}

// createMaintenancePublisher creates a new maintenance queue for storing
// errored messages in a queue for later processing
func (l *Consumer) createMaintenancePublisher(rmq *rabbitmq.RabbitMQ) (*rabbitmq.Producer, error) {
	exchange := rabbitmq.Exchange{
		Name: "",
	}

	publishingOptions := rabbitmq.PublishingOptions{
		Tag:       fmt.Sprintf("%sWorkerConsumer", l.WorkerName),
		Immediate: false,
	}

	return rmq.NewProducer(
		exchange,
		rabbitmq.Queue{
			Name:    "BrokerMaintenanceQueue",
			Durable: true,
		},
		publishingOptions,
	)
}
