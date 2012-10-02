package dnode

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strconv"
	"strings"
	"sync"
)

type DNode struct {
	SendChan     chan []byte
	Closed       bool
	OnRemote     func(remote Remote)
	OnReady      func()
	OnRootMethod func(method string, args *Partial)
	closeMutex   sync.Mutex
	callbacks    []reflect.Value
}

type Partial struct {
	Raw       []byte
	dnode     *DNode
	callbacks map[string]([]string)
}

func (p *Partial) MarshalJSON() ([]byte, error) {
	return p.Raw, nil
}

func (p *Partial) UnmarshalJSON(data []byte) error {
	if p == nil {
		return errors.New("json.Partial: UnmarshalJSON on nil pointer")
	}
	p.Raw = append(p.Raw[0:0], data...)
	return nil
}

func (p *Partial) Unmarshal(v interface{}) error {
	err := json.Unmarshal(p.Raw, v)
	if err != nil {
		return err
	}

	for id, path := range p.callbacks {
		methodId, err := strconv.Atoi(id)
		if err != nil {
			panic(err)
		}

		value := reflect.ValueOf(v)
		i := 0
	PATH_LOOP:
		for ; i < len(path); i++ {
			for value.Kind() == reflect.Ptr {
				if _, ok := value.Interface().(*Partial); ok {
					break PATH_LOOP
				}
				value = reflect.ValueOf(value.Elem().Interface())
			}

			switch value.Kind() {
			case reflect.Slice:
				index, err := strconv.Atoi(path[i])
				if err != nil {
					panic(fmt.Sprintf("Integer expected, got '%v'.", path[i]))
				}
				value = value.Index(index)
			case reflect.Map:
				value = value.MapIndex(reflect.ValueOf(path[i]))
			default:
				panic(fmt.Sprintf("Unhandled object of type '%T'.", value.Interface()))
			}
		}

		fmt.Printf("%T\n", value.Interface())
		if partial, ok := value.Interface().(*Partial); ok {
			partial.dnode = p.dnode
			if partial.callbacks == nil {
				partial.callbacks = make(map[string]([]string))
			}
			partial.callbacks[id] = path[i:]
		} else {
			callback := reflect.ValueOf(Callback(func(args ...interface{}) {
				p.dnode.Send(methodId, args)
			}))
			value.Set(callback)
		}
	}

	return nil
}

func (p *Partial) Array() ([]interface{}, error) {
	var a []interface{}
	err := p.Unmarshal(&a)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func (p *Partial) Map() (map[string]interface{}, error) {
	var m map[string]interface{}
	err := p.Unmarshal(&m)
	if err != nil {
		return nil, err
	}
	return m, nil
}

type message struct {
	Method    interface{}           `json:"method"`
	Arguments *Partial              `json:"arguments"`
	Links     []string              `json:"links"`
	Callbacks map[string]([]string) `json:"callbacks"`
}

type Remote map[string]interface{}

type Callback func(args ...interface{})

func New() *DNode {
	d := DNode{
		make(chan []byte),
		false,
		nil, nil, nil,
		sync.Mutex{},
		make([]reflect.Value, 0),
	}
	return &d
}

func (d *DNode) SendRemote(object interface{}) {
	d.Send("methods", []interface{}{object})
}

func (d *DNode) Send(method interface{}, arguments []interface{}) {
	rawArgs, err := json.Marshal(arguments)
	if err != nil {
		panic(err)
	}
	message := message{
		method,
		&Partial{Raw: rawArgs},
		[]string{},
		make(map[string]([]string)),
	}
	d.collectCallbacks(arguments, make([]string, 0), message.Callbacks)
	data, err := json.Marshal(message)
	if err != nil {
		panic(err)
	}

	d.closeMutex.Lock()
	defer d.closeMutex.Unlock()
	if !d.Closed {
		d.SendChan <- data
	}
}

func (d *DNode) Close() {
	d.closeMutex.Lock()
	defer d.closeMutex.Unlock()
	d.Closed = true
	close(d.SendChan)
}

func (d *DNode) collectCallbacks(rawObj interface{}, path []string, callbackMap map[string]([]string)) {
	switch obj := rawObj.(type) {
	case nil:
		// skip
	case []interface{}:
		for i, v := range obj {
			d.collectCallbacks(v, append(path, strconv.Itoa(i)), callbackMap)
		}
	case map[string]interface{}:
		for key, value := range obj {
			v := reflect.ValueOf(value)
			if v.Kind() == reflect.Func {
				d.registerCallback(key, v, path, callbackMap)
				delete(obj, key)
			}
		}
	default:
		v := reflect.ValueOf(obj)
		for i := 0; i < v.NumMethod(); i++ {
			if v.Type().Method(i).PkgPath == "" { // exported
				name := v.Type().Method(i).Name
				name = strings.ToLower(name[0:1]) + name[1:]
				d.registerCallback(name, v.Method(i), path, callbackMap)
			}
		}
	}
}

func (d *DNode) registerCallback(name string, callback reflect.Value, path []string, callbackMap map[string]([]string)) {
	pathCopy := make([]string, len(path)+1)
	copy(pathCopy, path)
	pathCopy[len(path)] = name

	callbackMap[strconv.Itoa(len(d.callbacks))] = pathCopy
	d.callbacks = append(d.callbacks, callback)
}

func (d *DNode) ProcessMessage(data []byte) {
	var m message
	err := json.Unmarshal(data, &m)
	if err != nil {
		panic(err)
	}
	m.Arguments.dnode = d
	m.Arguments.callbacks = m.Callbacks

	index, err := strconv.Atoi(fmt.Sprint(m.Method))
	if err == nil {
		args, err := m.Arguments.Array()
		if err != nil {
			panic(err)
		}
		callArgs := make([]reflect.Value, len(args))
		for i, v := range args {
			callArgs[i] = reflect.ValueOf(v)
		}
		d.callbacks[index].Call(callArgs)

	} else if m.Method == "methods" {
		var args [](map[string]interface{})
		err = m.Arguments.Unmarshal(&args)
		if err != nil {
			panic(err)
		}
		if d.OnRemote != nil {
			d.OnRemote(args[0])
		}
		if d.OnReady != nil {
			d.OnReady()
		}

	} else if d.OnRootMethod != nil {
		d.OnRootMethod(fmt.Sprint(m.Method), m.Arguments)

	} else {
		panic(fmt.Sprintf("Unknown method: %v.", m.Method))
	}
}
