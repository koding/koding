package rabbitmq

import (
	"fmt"
	"github.com/streadway/amqp"
)

type Consumer struct {
	*RabbitMQ
	deliveries <-chan amqp.Delivery
	handler    func(amqp.Delivery)
	done       chan error
	session    Session
}

func (c *Consumer) Deliveries() <-chan amqp.Delivery {
	return c.deliveries
}

func NewConsumer(e Exchange, q Queue, bo BindingOptions, co ConsumerOptions) (*Consumer, error) {

	rmq, err := newRabbitMQ(co.Tag)
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
	err := c.connect()
	if err != nil {
		return nil, err
	}

	return c, nil
}

func (c *Consumer) connect() error {

	e := c.session.Exchange
	q := c.session.Queue
	bo := c.session.BindingOptions
	co := c.session.ConsumerOptions

	var err error

	// getting Connection
	c.conn, err = amqp.Dial(getConnectionString())
	if err != nil {
		return err
	}
	handleErrors(c.conn)
	// getting Channel
	c.channel, err = c.conn.Channel()
	if err != nil {
		return err
	}

	// got channel, declaring Exchange
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
	queue, err := c.channel.QueueDeclare(
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

	// declared Queue, binding to Exchange
	if err = c.channel.QueueBind(
		// bind to real queue
		queue.Name,    // name of the queue
		bo.RoutingKey, // bindingKey
		e.Name,        // sourceExchange
		bo.NoWait,     // noWait
		bo.Args,       // arguments
	); err != nil {
		return err
	}

	// Queue bound to Exchange, starting Consume
	deliveries, err := c.channel.Consume(
		// consume from real queue
		queue.Name,   // name
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

	return nil
}

func (c *Consumer) Consume(handler func(deliveries <-chan amqp.Delivery)) {
	c.handler = handler

	// handle all consumer errors, if required re-connect
	// there are problems with reconnection logic
	handler(c.deliveries)

	// change fmt -> log
	fmt.Println("handle: deliveries channel closed")
	c.done <- nil
}

func (c *Consumer) Shutdown() error {
	err := shutdown(c.conn, c.channel, c.tag)
	if err != nil {
		return nil
	}
	// change fmt -> log
	defer fmt.Println("Consumer shutdown OK")
	fmt.Println("Waiting for handler to exit")
	return <-c.done
}

func (c *Consumer) RegisterSignalHandler() {
	registerSignalHandler(c)
}
