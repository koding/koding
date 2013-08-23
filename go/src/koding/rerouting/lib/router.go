package rerouting

import (
	"errors"
	"fmt"
	"github.com/fatih/goset"
	"github.com/streadway/amqp"
	"koding/tools/amqputil"
	"log"
)

type Consumer struct {
	Conn    *amqp.Connection
	Channel *amqp.Channel
}

type Producer struct {
	Conn    *amqp.Connection
	Channel *amqp.Channel
}

type AuthMsg struct {
	Name               string  `json:"name"`
	BindingExchange    string  `json:"bindingExchange"`
	BindingKey         string  `json:"bindingKey"`
	PublishingExchange *string `json:"publishingExchange"`
	RoutingKey         string  `json:"routingKey"`
	Suffix             string  `json:"suffix"`
}

type Route struct {
	length int
	joins  *goset.Set
}

type M map[string]interface{}

type Router struct {
	routes   M
	consumer *Consumer
	producer *Producer
}

func NewRouter(c *Consumer, p *Producer) *Router {
	router := new(Router)
	router.routes = M{}
	router.consumer = c
	router.producer = p
	return router
}

func (r *Router) AddRoute(join AuthMsg) error {

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

	if bindingKey[*join.PublishingExchange] == nil {
		bindingKey[*join.PublishingExchange] = M{}
	}
	publishingExchange := bindingKey[*join.PublishingExchange].(M)

	route, ok := publishingExchange[join.RoutingKey].(*Route)
	if !ok {
		publishingExchange[join.RoutingKey] = &Route{1, goset.New(join)}
		route = publishingExchange[join.RoutingKey].(*Route)
	} else {
		route.joins.Add(join)
	}

	if isNewBindingExchange {
		if err := r.addBinding(join.BindingExchange); err != nil {
			log.Println(err)
			return err
		}
	}

	log.Println(r.routes)

	return nil
}

func (r *Router) publishTo(join *AuthMsg, msg *amqp.Delivery) error {
	err := r.producer.Channel.Publish(
		*join.PublishingExchange,
		join.RoutingKey,
		false,
		false,
		amqp.Publishing{Headers: msg.Headers, Body: msg.Body},
	)

	return err
}

func (r *Router) addBinding(exchangeName string) error {

	c := amqputil.CreateChannel(r.consumer.Conn)

	var err error

	err = c.ExchangeDeclare(exchangeName, "topic", false, true, false, false, nil)
	if err != nil {
		log.Fatalf("exchange.declare: %s", err)
		return err
	}

	if _, err := c.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Fatalf("queue.declare: %s", err)
		return err
	}

	if err := c.QueueBind("", "#", exchangeName, false, nil); err != nil {
		log.Fatalf("queue.bind: %s", err)
		return err
	}

	deliveries, err := c.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
		return err
	}

	for msg := range deliveries {
		if r.routes[msg.Exchange] == nil {
			continue // drop it on the floor
		}
		bindingExchange := r.routes[msg.Exchange].(M)

		if bindingExchange[msg.RoutingKey] == nil {
			continue // drop it on the floor
		}
		bindingKey := bindingExchange[msg.RoutingKey].(M)

		for name := range bindingKey {
			publishingExchange := bindingKey[name].(M)

			for routingKey := range publishingExchange {
				route := publishingExchange[routingKey].(*Route)
				list := route.joins.List()

				for i := range list {
					joinMsg := list[i].(AuthMsg)
					if err := r.publishTo(&joinMsg, &msg); err != nil {
						log.Println(err)
					}
				}
			}
		}
	}

	return nil
}

func (r *Router) RemoveRoute(leave AuthMsg) error {

	if r.routes[leave.BindingExchange] == nil {
		return fmt.Errorf("Unknown binding exchange: %s", leave.BindingExchange)
	}
	bindingExchange := r.routes[leave.BindingExchange].(M)

	if bindingExchange[leave.BindingKey] == nil {
		return fmt.Errorf("Unknown binding key: %s", leave.BindingKey)
	}
	bindingKey := bindingExchange[leave.RoutingKey].(M)

	var publishingExchange M

	if bindingKey[*leave.PublishingExchange] == nil {
		publishingExchange = bindingKey["broker"].(M)
	} else {
		publishingExchange = bindingKey[*leave.PublishingExchange].(M)
	}

	if publishingExchange == nil {
		return fmt.Errorf("Unknown publishing exchange: %s", publishingExchange)
	}

	if publishingExchange[leave.RoutingKey] == nil {
		return fmt.Errorf("Unknown routing key: %s", leave.RoutingKey)
	}
	routingKey := publishingExchange[leave.RoutingKey].(M)

	log.Printf("%v", routingKey)

	return nil

}
