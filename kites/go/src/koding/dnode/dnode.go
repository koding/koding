package dnode

import (
	"encoding/json"
	"fmt"
	"io"
	"reflect"
	"strconv"
	"strings"
)

type DNode struct {
	decoder      *json.Decoder
	encoder      *json.Encoder
	callbacks    []reflect.Value
	OnRemote     func(remote Remote)
	OnReady      func()
	OnRootMethod func(method string, args []interface{})
}

type message struct {
	Method    interface{}           `json:"method"`
	Arguments []interface{}         `json:"arguments"`
	Links     []string              `json:"links"`
	Callbacks map[string]([]string) `json:"callbacks"`
}

type Remote map[string]interface{}

type Callback func(args ...interface{})

func New(connection io.ReadWriter) *DNode {
	dnode := DNode{
		json.NewDecoder(connection),
		json.NewEncoder(connection),
		make([]reflect.Value, 0),
		nil, nil, nil,
	}
	return &dnode
}

func (dnode *DNode) SendRemote(object interface{}) {
	dnode.Send("methods", []interface{}{object})
}

func (dnode *DNode) Send(method interface{}, arguments []interface{}) {
	message := message{
		method,
		arguments,
		[]string{},
		make(map[string]([]string)),
	}
	dnode.collectCallbacks(arguments, make([]string, 0), message.Callbacks)
	dnode.encoder.Encode(message)
}

func (dnode *DNode) collectCallbacks(obj interface{}, path []string, callbackMap map[string]([]string)) {
	switch obj.(type) {
	case []interface{}:
		for i, v := range obj.([]interface{}) {
			dnode.collectCallbacks(v, append(path, strconv.Itoa(i)), callbackMap)
		}

	default:
		v := reflect.ValueOf(obj)
		for i := 0; i < v.NumMethod(); i++ {
			name := v.Type().Method(i).Name
			name = strings.ToLower(name[0:1]) + name[1:]

			pathCopy := make([]string, len(path)+1)
			copy(pathCopy, path)
			pathCopy[len(path)] = name

			callbackMap[strconv.Itoa(len(dnode.callbacks))] = pathCopy
			dnode.callbacks = append(dnode.callbacks, v.Method(i))
		}
	}
}

func (dnode *DNode) Run() {
	for {
		var m message
		err := dnode.decoder.Decode(&m)

		if err != nil {
			if err != io.EOF {
				panic(err)
			}
			break
		}

		for id, path := range m.Callbacks {
			methodId, err := strconv.Atoi(id)
			if err != nil {
				panic(err)
			}
			callback := Callback(func(args ...interface{}) {
				dnode.Send(methodId, args)
			})

			var obj interface{} = m.Arguments
			for i := 0; i < len(path); i++ {
				isLast := i == len(path)-1
				switch obj.(type) {
				case []interface{}:
					index, err := strconv.Atoi(path[i])
					if err != nil {
						panic(fmt.Sprintf("Integer expected, got %v.", path[i]))
					}
					if isLast {
						obj.([]interface{})[index] = callback
					} else {
						obj = obj.([]interface{})[index]
					}
				case map[string]interface{}:
					if isLast {
						obj.(map[string]interface{})[path[i]] = callback
					} else {
						obj = obj.(map[string]interface{})[path[i]]
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
			dnode.callbacks[index].Call(args)
		} else if m.Method == "methods" {
			remote := m.Arguments[0].(map[string]interface{})
			if dnode.OnRemote != nil {
				dnode.OnRemote(remote)
			}
			if dnode.OnReady != nil {
				dnode.OnReady()
			}
		} else if dnode.OnRootMethod != nil {
			dnode.OnRootMethod(fmt.Sprint(m.Method), m.Arguments)
		} else {
			panic(fmt.Sprintf("Unknown method: %v.", m.Method))
		}
	}
}
