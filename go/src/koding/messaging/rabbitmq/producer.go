package rabbitmq

import (
	"errors"
	"fmt"
	"github.com/streadway/amqp"
)

type Producer struct {
	conn       *amqp.Connection
	channel    *amqp.Channel
	deliveries <-chan amqp.Delivery
	tag        string
	handler    func(deliveries <-chan amqp.Delivery)
	done       chan error
	session    Session
}

type PublishingOptions struct {
	RoutingKey, Tag      string
	Mandatory, Immediate bool
}

func NewProducer(e Exchange, q Queue, po PublishingOptions) (*Producer, error) {
	if po.Tag == "" {
		return nil, errors.New("Tag is not defined in consumer options")
	}

	p := &Producer{
		conn:    nil,
		channel: nil,
		tag:     po.Tag,
		session: Session{
			Exchange:          e,
			Queue:             q,
			PublishingOptions: po,
		},
	}

	err := p.connect()
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (p *Producer) connect() error {

	var err error
	p.conn, err = amqp.Dial(getConnectionString())
	if err != nil {
		return err
	}
	handleErrors(p.conn)
	// got Connection, getting Channel
	p.channel, err = p.conn.Channel()
	if err != nil {
		return err
	}

	return nil
}

func (p *Producer) Publish(publishing amqp.Publishing) error {
	e := p.session.Exchange
	q := p.session.Queue
	po := p.session.PublishingOptions

	routingKey := po.RoutingKey
	// if exchange name is empty, this means we are gonna publish
	// this mesage to a queue, every queue has a binding to default exchange
	if e.Name == "" {
		routingKey = q.Name
	}

	err := p.channel.Publish(
		e.Name,       // publish to an exchange(it can be default exchange)
		routingKey,   // routing to 0 or more queues
		po.Mandatory, // mandatory, if no queue than err
		po.Immediate, // immediate, if no consumer than err
		publishing,
		// amqp.Publishing{
		// 	Headers:         amqp.Table{},
		// 	ContentType:     "text/plain",
		// 	ContentEncoding: "",
		// 	Body:            []byte(body),
		// 	DeliveryMode:    amqp.Transient, // 1=non-persistent, 2=persistent
		// 	Priority:        0,              // 0-9
		// 	// a bunch of application/implementation-specific fields
		// },
	)

	return err
}

func (p *Producer) Shutdown() error {
	err := shutdown(p.conn, p.channel, p.tag)
	defer fmt.Println("Producer shutdown OK")
	return err
}

func (p *Producer) RegisterSignalHandler() {
	registerSignalHandler(p)
}
