package dnode

import (
	"encoding/json"
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

type message struct {
	Method    interface{}           `json:"method"`
	Arguments *Partial              `json:"arguments"`
	Links     []string              `json:"links"`
	Callbacks map[string]([]string) `json:"callbacks"`
}

type Remote map[string]interface{}

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
	d.Send("methods", object)
}

func (d *DNode) Send(method interface{}, arguments ...interface{}) {
	callbacks := make(map[string]([]string))
	d.collectCallbacks(arguments, make([]string, 0), callbacks)

	rawArgs, err := json.Marshal(arguments)
	if err != nil {
		panic(err)
	}

	message := message{
		method,
		&Partial{Raw: rawArgs},
		[]string{},
		callbacks,
	}
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
	for id, path := range m.Callbacks {
		methodId, err := strconv.Atoi(id)
		if err != nil {
			panic(err)
		}
		callback := Callback(func(args ...interface{}) {
			d.Send(methodId, args...)
		})
		m.Arguments.callbacks = append(m.Arguments.callbacks, CallbackSpec{path, callback})
	}

	if m.Method == "methods" {
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
		return
	}

	if index, err := strconv.Atoi(fmt.Sprint(m.Method)); err == nil {
		args, err := m.Arguments.Array()
		if err != nil {
			panic(err)
		}
		if index < 0 || index >= len(d.callbacks) {
			return
		}
		callArgs := make([]reflect.Value, len(args))
		for i, v := range args {
			callArgs[i] = reflect.ValueOf(v)
		}
		d.callbacks[index].Call(callArgs)
		return
	}

	if d.OnRootMethod != nil {
		d.OnRootMethod(fmt.Sprint(m.Method), m.Arguments)
		return
	}

	panic(fmt.Sprintf("Unknown method: %v.", m.Method))
}
