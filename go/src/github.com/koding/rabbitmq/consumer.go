package rabbitmq

import "github.com/streadway/amqp"

type Consumer struct {
	// Base struct for Producer
	*RabbitMQ

	// All deliveries from server will send to this channel
	deliveries <-chan amqp.Delivery

	// This handler will be called when a
	handler func(amqp.Delivery)

	// A notifiyng channel for publishings
	// will be used for sync. between close channel and consume handler
	done chan error

	// Current producer connection settings
	session Session
}

func (c *Consumer) Deliveries() <-chan amqp.Delivery {
	return c.deliveries
}

// NewConsumer is a constructor for consumer creation
// Accepts Exchange, Queue, BindingOptions and ConsumerOptions
func (r *RabbitMQ) NewConsumer(e Exchange, q Queue, bo BindingOptions, co ConsumerOptions) (*Consumer, error) {
	rmq, err := r.Connect(co.Tag)
	if err != nil {
		return nil, err
	}

	c := &Consumer{
		RabbitMQ: rmq,
		done:     make(chan error),
		session: Session{
			Exchange:        e,
			Queue:           q,
			ConsumerOptions: co,
			BindingOptions:  bo,
		},
	}

	err = c.connect()
	if err != nil {
		return nil, err
	}

	return c, nil
}

// connect internally declares the exchanges and queues
// and starts to stream from given queue
func (c *Consumer) connect() error {
	e := c.session.Exchange
	q := c.session.Queue
	bo := c.session.BindingOptions

	var err error

	// declaring Exchange
	if err = c.channel.ExchangeDeclare(
		e.Name,       // name of the exchange
		e.Type,       // type
		e.Durable,    // durable
		e.AutoDelete, // delete when complete
		e.Internal,   // internal
		e.NoWait,     // noWait
		e.Args,       // arguments
	); err != nil {
		return err
	}

	// declaring Queue
	_, err = c.channel.QueueDeclare(
		q.Name,       // name of the queue
		q.Durable,    // durable
		q.AutoDelete, // delete when usused
		q.Exclusive,  // exclusive
		q.NoWait,     // noWait
		q.Args,       // arguments
	)
	if err != nil {
		return err
	}

	// binding Exchange to Queue
	if err = c.channel.QueueBind(
		// bind to real queue
		q.Name,        // name of the queue
		bo.RoutingKey, // bindingKey
		e.Name,        // sourceExchange
		bo.NoWait,     // noWait
		bo.Args,       // arguments
	); err != nil {
		return err
	}

	return nil
}

// Consume accepts a handler function for every message streamed from RabbitMq
// will be called within this handler func
func (c *Consumer) Consume(handler func(delivery amqp.Delivery)) error {
	co := c.session.ConsumerOptions
	q := c.session.Queue
	// Exchange bound to Queue, starting Consume
	deliveries, err := c.channel.Consume(
		// consume from real queue
		q.Name,       // name
		co.Tag,       // consumerTag,
		co.AutoAck,   // autoAck
		co.Exclusive, // exclusive
		co.NoLocal,   // noLocal
		co.NoWait,    // noWait
		co.Args,      // arguments
	)
	if err != nil {
		return err
	}

	// should we stop streaming, in order not to consume from server?
	c.deliveries = deliveries
	c.handler = handler

	c.RabbitMQ.log.Info("handle: deliveries channel starting")

	// handle all consumer errors, if required re-connect
	// there are problems with reconnection logic for now
	for delivery := range c.deliveries {
		handler(delivery)
	}

	c.RabbitMQ.log.Info("handle: deliveries channel closed")
	c.done <- nil
	return nil
}

// ConsumeMessage accepts a handler function and only consumes one message
// stream from RabbitMq and then closes connection
func (c *Consumer) Get(handler func(delivery amqp.Delivery)) error {
	co := c.session.ConsumerOptions
	q := c.session.Queue
	message, ok, err := c.channel.Get(q.Name, co.AutoAck)
	if err != nil {
		return err
	}

	c.handler = handler

	if ok {
		c.RabbitMQ.log.Debug("Message received")
		handler(message)
	} else {
		c.RabbitMQ.log.Debug("No message received")
	}

	return shutdown(c.conn, c.channel, c.tag)
}

// Shutdown gracefully closes all connections and waits
// for handler to finish its messages
func (c *Consumer) Shutdown() error {
	// to-do
	// first stop streaming then close connections
	err := shutdown(c.conn, c.channel, c.tag)
	if err != nil {
		return err
	}

	defer c.RabbitMQ.log.Info("Consumer shutdown OK")
	c.RabbitMQ.log.Info("Waiting for Consumer handler to exit")

	// if we have not called the Consume yet, we can return here
	if c.deliveries == nil {
		close(c.done)
	}

	// this channel is here for finishing the consumer's ranges of
	// delivery chans.  We need every delivery to be processed, here make
	// sure to wait for all consumers goroutines to finish before exiting our
	// process.
	return <-c.done
}

// RegisterSignalHandler watchs for interrupt signals
// and gracefully closes consumer
func (c *Consumer) RegisterSignalHandler() {
	registerSignalHandler(c)
}
