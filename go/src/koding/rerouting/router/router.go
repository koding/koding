package rerouting

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/tools/amqputil"
	"koding/tools/logger"
	"sync"

	"github.com/fatih/set"
	"github.com/streadway/amqp"
)

var log = logger.New("router")

type Consumer struct {
	Conn    *amqp.Connection
	Channel *amqp.Channel
}

type Producer struct {
	Conn    *amqp.Connection
	Channel *amqp.Channel
}

type authMsgJson struct {
	BindingExchange    string  `json:"bindingExchange"`
	BindingKey         string  `json:"bindingKey"`
	PublishingExchange *string `json:"publishingExchange"`
	RoutingKey         string  `json:"routingKey"`
}

type AuthMsg struct {
	BindingExchange    string
	BindingKey         string
	PublishingExchange string
	RoutingKey         string
}

type M map[string]interface{}

type Router struct {
	routes       M
	consumer     *Consumer
	producer     *Producer
	sync.RWMutex // protects routes
}

func NewRouter(c *Consumer, p *Producer, profile string) *Router {
	return &Router{
		routes:   M{},
		consumer: c,
		producer: p,
	}
}

func (r *Router) AddRoute(msg *amqp.Delivery) error {
	join, err := createAuthMsg(msg)
	if err != nil {
		return err
	}

	if (join.BindingExchange == "") || (join.BindingKey == "") || (join.RoutingKey == "") {
		return errors.New("Bad join message: Ignoring")
	}

	isNewBindingExchange := false

	if r.routes[join.BindingExchange] == nil {
		r.routes[join.BindingExchange] = M{}
		isNewBindingExchange = true
	}
	bindingExchange := r.routes[join.BindingExchange].(M)

	if bindingExchange[join.BindingKey] == nil {
		bindingExchange[join.BindingKey] = M{}
	}
	bindingKey := bindingExchange[join.BindingKey].(M)

	if bindingKey[join.PublishingExchange] == nil {
		bindingKey[join.PublishingExchange] = M{}
	}
	publishingExchange := bindingKey[join.PublishingExchange].(M)

	if routes, ok := publishingExchange[join.RoutingKey].(*set.Set); ok {
		routes.Add(*join)
	} else {
		publishingExchange[join.RoutingKey] = set.New(*join)
	}

	if isNewBindingExchange {
		go func() {
			if err := r.addBinding(join.BindingExchange); err != nil {
				log.Error("Error adding binding: %v", err)
			}
		}()
	}

	return nil
}

func (r *Router) RemoveRoute(msg *amqp.Delivery) error {
	leave, err := createAuthMsg(msg)
	if err != nil {
		return err
	}

	if r.routes[leave.BindingExchange] == nil {
		return fmt.Errorf("Unknown binding exchange: %s", leave.BindingExchange)
	}
	bindingExchange := r.routes[leave.BindingExchange].(M)

	if leave.BindingKey == "" {
		return errors.New("No binding key provided")
	}

	if bindingExchange[leave.BindingKey] == nil {
		return fmt.Errorf("Unknown binding key: %s", leave.BindingKey)
	}

	bindingKey := bindingExchange[leave.BindingKey].(M)

	if bindingKey[leave.PublishingExchange] == nil {
		return fmt.Errorf("Unknown publishing exchange: %s", leave.BindingKey)
	}

	publishingExchange := bindingKey[leave.PublishingExchange].(M)

	if publishingExchange[leave.RoutingKey] == nil {
		return fmt.Errorf("Unknown routing key: %s", leave.RoutingKey)
	}

	routes := publishingExchange[leave.RoutingKey].(*set.Set)

	for _, join := range routes.List() {
		if *leave == join.(AuthMsg) {
			routes.Remove(join)
		}
	}

	return nil

}

func (r *Router) publishTo(join *AuthMsg, msg *amqp.Delivery) error {
	return r.producer.Channel.Publish(
		join.PublishingExchange, // exchange name
		join.RoutingKey,         // routing key
		false,                   // mandatory
		false,                   // immediate
		amqp.Publishing{Headers: msg.Headers, Body: msg.Body}, // args
	)
}

func (r *Router) addBinding(exchange string) error {

	r.RLock()
	c := amqputil.CreateChannel(r.consumer.Conn)
	r.RUnlock()

	var err error

	err = c.ExchangeDeclare(
		exchange, // exchange name
		"topic",  // exchange type
		false,    // durable
		true,     // auto-delete
		false,    // internal
		false,    // no-wait
		nil,      // args
	)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
		return err
	}

	if _, err := c.QueueDeclare(
		"",    // queue name
		false, // durable
		true,  // auto-delete
		false, // exclusive
		false, // no-wait
		nil,   // args
	); err != nil {
		log.Fatal("queue.declare: %s", err)
		return err
	}

	if err := c.QueueBind(
		"",       // queue name
		"#",      // routing key
		exchange, // exchange name
		false,    // no-wait
		nil,      // args
	); err != nil {
		log.Fatal("queue.bind: %s", err)
		return err
	}

	deliveries, err := c.Consume(
		"",    // queue name
		"",    // consumer tag
		true,  // auto-ack
		false, // exclusive
		false, // no-local
		false, // no-wait
		nil,   // args
	)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
		return err
	}

	for msg := range deliveries {

		r.RLock()

		if r.routes[msg.Exchange] == nil {
			r.RUnlock()
			continue // drop it on the floor
		}
		bindingExchange := r.routes[msg.Exchange].(M)

		if bindingExchange[msg.RoutingKey] == nil {
			r.RUnlock()
			continue // drop it on the floor
		}
		bindingKey := bindingExchange[msg.RoutingKey].(M)

		for name := range bindingKey {
			publishingExchange := bindingKey[name].(M)

			for routingKey := range publishingExchange {
				routes := publishingExchange[routingKey].(*set.Set)
				list := routes.List()

				for i := range list {
					joinMsg := list[i].(AuthMsg)
					if err := r.publishTo(&joinMsg, &msg); err != nil {
						log.Warning("WARNING: %v", err)
					}
				}
			}
		}

		r.RUnlock()
	}

	return nil
}

func createAuthMsg(msg *amqp.Delivery) (*AuthMsg, error) {
	var msgJson authMsgJson

	if err := json.Unmarshal(msg.Body, &msgJson); err != nil {
		return nil, err
	}

	authMsg := AuthMsg{
		BindingExchange: msgJson.BindingExchange,
		BindingKey:      msgJson.BindingKey,
		RoutingKey:      msgJson.RoutingKey,
	}

	if msgJson.PublishingExchange == nil {
		authMsg.PublishingExchange = "broker"
	} else {
		authMsg.PublishingExchange = *msgJson.PublishingExchange
	}

	return &authMsg, nil
}
