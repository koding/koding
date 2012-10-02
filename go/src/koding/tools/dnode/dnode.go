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
	OnRootMethod func(method string, args []interface{})
	closeMutex   sync.Mutex
	callbacks    []reflect.Value
}

type message struct {
	Method    interface{}           `json:"method"`
	Arguments []interface{}         `json:"arguments"`
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
	message := message{
		method,
		arguments,
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

	for id, path := range m.Callbacks {
		methodId, err := strconv.Atoi(id)
		if err != nil {
			panic(err)
		}
		callback := Callback(func(args ...interface{}) {
			d.Send(methodId, args)
		})

		var rawObj interface{} = m.Arguments
		for i := 0; i < len(path); i++ {
			isLast := i == len(path)-1
			switch obj := rawObj.(type) {
			case []interface{}:
				index, err := strconv.Atoi(path[i])
				if err != nil {
					panic(fmt.Sprintf("Integer expected, got %v.", path[i]))
				}
				if isLast {
					obj[index] = callback
				} else {
					rawObj = obj[index]
				}
			case map[string]interface{}:
				if isLast {
					obj[path[i]] = callback
				} else {
					rawObj = obj[path[i]]
				}
			default:
				panic(fmt.Sprintf("Unhandled object type %T of %v.", obj, obj))
			}
		}
	}

	index, err := strconv.Atoi(fmt.Sprint(m.Method))
	if err == nil {
		args := make([]reflect.Value, len(m.Arguments))
		for i, v := range m.Arguments {
			args[i] = reflect.ValueOf(v)
		}
		d.callbacks[index].Call(args)
	} else if m.Method == "methods" {
		remote := m.Arguments[0].(map[string]interface{})
		if d.OnRemote != nil {
			d.OnRemote(remote)
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
