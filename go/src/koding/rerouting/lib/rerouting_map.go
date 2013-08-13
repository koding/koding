package rerouting

import (
	"github.com/streadway/amqp"
)

type JoinMsg struct {
	Name               string  `json:"name"`
	BindingExchange    string  `json:"bindingExchange"`
	BindingKey         string  `json:"bindingKey"`
	PublishingExchange *string `json:"publishingExchange"`
	RoutingKey         string  `json:"routingKey"`
	ConsumerTag        string
	Suffix             string `json:"suffix"`
	Channel            *amqp.Channel
}

type LeaveMsg struct {
	BindingExchange string `json:"bindingExchange"`
	RoutingKey 			string `json:"routingKey"`
	PublishingExchange string `json:"publishingExchange"`
}

type Router struct {
	routes map[string]interface{}
}

func NewRouter() *Router {
	router := new(Router)
	router.routes = make(map[string]interface{})
	return router
}

func (r *Router) AddRoute(join JoinMsg) bool {

	isNewBindingExchange := false

	bindingExchange, ok := r.routes[join.BindingExchange].(map[string]interface{})

	if !ok {
		bindingExchange = make(map[string]interface{})
		r.routes[join.BindingExchange] = bindingExchange
		isNewBindingExchange = true
	}

	bindingKey, ok := bindingExchange[join.RoutingKey]

	if !ok {
		bindingKey = make([]interface{}, 0)
		bindingExchange[join.RoutingKey] = bindingKey
	}

	append(bindingKey, join)

	return isNewBindingExchange
}

func (r *Router) RemoveRoute(leave LeaveMsg) {

	isUnusedBindingExchange := false

	bindingExchange, ok := r.routes[]

}
