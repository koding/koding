package broker

import (
	"bytes"
	"encoding/json"
	"fmt"
	"reflect"

	"github.com/jinzhu/gorm"
	"github.com/streadway/amqp"
	"gopkg.in/mgo.v2"
)

type Handler interface {
	HandleEvent(string, []byte) error
	ErrHandler
}

type ErrHandler interface {
	// bool is whether publishing the message to maintenance qeueue or not
	DefaultErrHandler(amqp.Delivery, error) bool
}

func (c *Consumer) withMetrics(handler *SubscriptionHandler, delivery amqp.Delivery) error {
	// if metrics is not enabled just invoke the function
	if c.Metrics == nil {
		return handler.HandleEvent(c.contextValue, delivery.Body)
	}

	c.Metrics.GetCounter("message").Inc(1)

	var err error

	c.Metrics.GetTimer(delivery.Type).Time(func() {
		err = handler.HandleEvent(c.contextValue, delivery.Body)
	})

	return err
}

func (c *Consumer) withCounter(counterName string, fn func()) {
	if c.Metrics == nil {
		fn()
	}

	c.Metrics.GetCounter(counterName).Inc(1)
	fn()
}

func (c *Consumer) Start() func(delivery amqp.Delivery) {
	c.Log.Info("Broker sarted to consume")
	return func(delivery amqp.Delivery) {
		if _, ok := c.handlers[delivery.Type]; !ok {
			// if no handler found, just ack message
			c.Log.Debug("No handler for %s", delivery.Type)
			c.withCounter("nohandlerforevent", func() { delivery.Ack(false) })
			return
		}

		go func() {
			var err error
			for _, handler := range c.handlers[delivery.Type] {
				// do not continue, if one of the handler gives error
				if err != nil {
					break
				}

				err = c.withMetrics(handler, delivery)
			}
			c.handleError(err, delivery)
		}()

	}
}

func (c *Consumer) handleError(err error, delivery amqp.Delivery) {
	switch err {
	case nil:
		c.withCounter("success", func() { delivery.Ack(false) })
	case ErrNoHandlerFound:
		c.withCounter("handlernotfound", func() { delivery.Ack(false) })
		c.Log.Debug("unknown event type (%s) recieved, deleting message from RMQ", delivery.Type)
	case gorm.RecordNotFound:
		c.withCounter("gormrecordnotfound", func() { delivery.Ack(false) })
		c.Log.Warning("Record not found in our db (%s) recieved, deleting message from RMQ", string(delivery.Body))
	case mgo.ErrNotFound:
		c.withCounter("mgorecordnotfound", func() { delivery.Ack(false) })
		c.Log.Warning("Record not found in our mongo db (%s) recieved, deleting message from RMQ", string(delivery.Body))
	default:
		c.withCounter("othererror", func() {
			// default err handler should handle the ack process
			if c.context.DefaultErrHandler(delivery, err) {
				if c.MaintenancePublisher == nil {
					return
				}

				data, err := json.Marshal(delivery)
				if err != nil {
					return
				}

				msg := amqp.Publishing{
					Body:  []byte(data),
					AppId: c.WorkerName,
				}

				c.withCounter("publishedtomaintenancequeue", func() {
					c.MaintenancePublisher.Publish(msg)
				})
			}
		})
	}
}

type SubscriptionHandler struct {
	v reflect.Value
}

func NewSubscriptionHandler(i interface{}) (*SubscriptionHandler, error) {
	t := reflect.TypeOf(i)
	if t.Kind() != reflect.Func {
		return nil, fmt.Errorf("kind was %v, not Func", t.Kind())
	}

	// check input parameter count
	if t.NumIn() != 2 {
		return nil, fmt.Errorf("input arity was %v, not 2", t.NumIn())
	}

	// check output parameter count
	if t.NumOut() != 1 {
		return nil, fmt.Errorf("output arity was %v, not 1", t.NumOut())
	}

	// output should be errors
	if t.Out(0).String() != "error" {
		return nil, fmt.Errorf("type of return value was %v, not error", t.Out(0))
	}

	return &SubscriptionHandler{reflect.ValueOf(i)}, nil
}

var nilParameter = reflect.ValueOf((*interface{})(nil))

func (m *SubscriptionHandler) HandleEvent(controllerValue reflect.Value, data []byte) error {
	var parameter reflect.Value

	if m.v.Type().NumIn() == 2 {
		in2 := m.v.Type().In(1)
		// if incoming paramter is an empty interface
		if reflect.Interface == in2.Kind() && in2.NumMethod() == 0 {
			parameter = nilParameter
			// if incoming parameter is a slice or a map
		} else if reflect.Slice == in2.Kind() || reflect.Map == in2.Kind() {
			// non-pointer maps/slices require special treatment because
			// json.Unmarshal won't work on a non-pointer destination. We
			// add a level indirection here, then deref it before .Call()
			parameter = reflect.New(in2)
		} else {
			// if it is a struct
			parameter = reflect.New(in2.Elem())
		}
	} else {
		// if handler doesnt have any incoming paramters
		parameter = nilParameter
	}

	// this is where magic happens:)
	// first read incoming []byte data into a io.reader then
	// put this data into a decoder(create a decoder out of it)
	// finally decode this data into given
	decoder := reflect.ValueOf(json.NewDecoder(bytes.NewReader(data)))
	res := decoder.MethodByName("Decode").Call([]reflect.Value{parameter})
	if len(res) > 0 && !res[0].IsNil() {
		return res[0].Interface().(error)
	}

	if reflect.Slice == parameter.Elem().Kind() || reflect.Map == parameter.Elem().Kind() {
		parameter = parameter.Elem()
	}

	var out []reflect.Value
	switch m.v.Type().NumIn() {
	case 2:
		out = m.v.Call([]reflect.Value{
			controllerValue,
			parameter,
		})
	// case 3:
	// 	out = m.v.Call([]reflect.Value{
	// 		controllerValue,
	// 		parameter,
	// 		reflect.ValueOf(logging),
	// 	})
	default:
		return fmt.Errorf("unknown signature %s", m.v.Type())
	}

	if len(out) > 0 && !out[0].IsNil() {
		return out[0].Interface().(error)
	}

	return nil
}
