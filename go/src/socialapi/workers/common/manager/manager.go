package manager

import (
	"bytes"
	"encoding/json"
	"fmt"
	"reflect"

	"github.com/koding/worker"
	"github.com/streadway/amqp"
)

func New() *Manager {
	return &Manager{}
}

type Manager struct {
	routes          map[string]*Marshaler
	controller      worker.ErrHandler
	controllerValue reflect.Value
}

func (c *Manager) Controller(controller worker.ErrHandler) {
	c.controller = controller
	c.controllerValue = reflect.ValueOf(controller)
}

func (b *Manager) HandleFunc(funcName string, handler interface{}) error {
	if b.routes == nil {
		b.routes = make(map[string]*Marshaler)
	}

	b.routes[funcName] = Marshaled(handler)
	return nil
}

func (b *Manager) HandleEvent(eventName string, data []byte) error {
	route, ok := b.routes[eventName]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	return route.HandleEvent(b.controllerValue, data)
}

func (m *Manager) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	return m.controller.DefaultErrHandler(delivery, err)
}

type Marshaler struct {
	v reflect.Value
}

func Marshaled(i interface{}) *Marshaler {
	t := reflect.TypeOf(i)
	if t.Kind() != reflect.Func {
		panic(NewMarshalerError("kind was %v, not Func", t.Kind()))
	}

	// check input parameter count
	if t.NumIn() != 2 {
		panic(NewMarshalerError(
			"input arity was %v, not 2",
			t.NumIn(),
		))
	}

	// check output parameter count
	if t.NumOut() != 1 {
		panic(NewMarshalerError("output arity was %v, not 1", t.NumOut()))
	}

	// output should be errors
	if t.Out(0).String() != "error" {
		panic(NewMarshalerError(
			"type of return value was %v, not error",
			t.Out(0),
		))
	}
	return &Marshaler{reflect.ValueOf(i)}
}

func (m *Marshaler) HandleEvent(controllerValue reflect.Value, data []byte) error {
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
	default:
		return fmt.Errorf("unknown signature %s", m.v.Type())
	}

	if len(out) > 0 && !out[0].IsNil() {
		return out[0].Interface().(error)
	}

	return nil
}

type MarshalerError string

func NewMarshalerError(format string, args ...interface{}) MarshalerError {
	return MarshalerError(fmt.Sprintf(format, args...))
}

func (e MarshalerError) Error() string { return string(e) }

var nilParameter = reflect.ValueOf((*interface{})(nil))
