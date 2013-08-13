package rerouting

import (
	"errors"
	"github.com/streadway/amqp"
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

type JoinMsg struct {
	Name               string  `json:"name"`
	BindingExchange    string  `json:"bindingExchange"`
	BindingKey         string  `json:"bindingKey"`
	PublishingExchange *string `json:"publishingExchange"`
	RoutingKey         string  `json:"routingKey"`
	Suffix             string  `json:"suffix"`
}

type LeaveMsg struct {
	BindingExchange    string `json:"bindingExchange"`
	BindingKey         string `json:"bindingKey"`
	RoutingKey         string `json:"routingKey"`
	PublishingExchange string `json:"publishingExchange"`
}

type Route struct {
	length int
	joins  map[int]*JoinMsg
}

type Router struct {
	routes   map[string]map[string]map[string]map[string]Route
	consumer *Consumer
}

func NewRouter(c *Consumer) *Router {
	router := new(Router)
	router.routes = make(map[string]map[string]map[string]map[string]Route)
	return router
}

func (r *Router) AddRoute(join JoinMsg) error {

	if (join.BindingExchange == "") || (join.BindingKey == "") || (join.RoutingKey == "") {
		return errors.New("Bad join message: Ignoring")
	}

	isNewBindingExchange := false

	if r.routes[join.BindingExchange] == nil {
		r.routes[join.BindingExchange] = map[string]map[string]map[string]Route{}
		isNewBindingExchange = true
	}
	bindingExchange := r.routes[join.BindingExchange]

	if bindingExchange[join.RoutingKey] == nil {
		bindingExchange[join.RoutingKey] = map[string]map[string]Route{}
	}
	bindingKey := bindingExchange[join.RoutingKey]

	if bindingKey[*join.PublishingExchange] == nil {
		bindingKey[*join.PublishingExchange] = map[string]Route{}
	}
	publishingExchange := bindingKey[*join.PublishingExchange]

	route, ok := publishingExchange[join.RoutingKey]
	if !ok {
		route = Route{1, map[int]*JoinMsg{}}
		route.joins[0] = &join
		publishingExchange[join.RoutingKey] = route
	} else {
		route.joins[route.length] = &join
		route.length++
		publishingExchange[join.RoutingKey] = route
	}

	if isNewBindingExchange {
		if err := r.addBinding(join.BindingExchange); err != nil {
			return err
		}
	}

	return nil
}

func (r *Router) addBinding(exchangeName string) error {
	log.Printf("need to add a binding to: %v", exchangeName)
	return nil
}

func (r *Router) RemoveRoute(leave LeaveMsg) error {

	bindingExchange := r.routes[leave.BindingExchange]

	bindingKey := bindingExchange[leave.RoutingKey]

	log.Printf("%v", bindingKey)

	return nil

}
