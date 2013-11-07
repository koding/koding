// https://github.com/substack/dnode-protocol/blob/master/doc/protocol.markdown
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
	Callbacks    []reflect.Value
}

// Message is the JSON object to call a method at the other side.
type Message struct {
	Method    interface{}           `json:"method"`
	Arguments *Partial              `json:"arguments"`
	Links     []string              `json:"links"`
	Callbacks map[string]([]string) `json:"callbacks"`
}

type Remote map[string]interface{}

// New returns a pointer to a new DNode.
func New() *DNode {
	return &DNode{
		SendChan:     make(chan []byte),
		Closed:       false,
		OnRemote:     nil,
		OnReady:      nil,
		OnRootMethod: nil,
		closeMutex:   sync.Mutex{},
		Callbacks:    make([]reflect.Value, 0),
	}
}

// SendRemote sends the supported methods to the other side.
//
// After the connection is established, each side should send a message
// with the method field set to "methods". The arguments fields should
// contain an array with a single element: the object that should be
// wrapped. After methods are exchanged, each side may request methods
// from the other based on named keys or numeric callback IDs.
//
// For the object:
//     { "timesTen" : "[Function]", "moo" : "[Function]" }
//
// the following Message will be sent:
//     {
//         "method" : "methods",
//         "arguments" : [ { "timesTen" : "[Function]", "moo" : "[Function]" } ],
//         "callbacks" : { "0" : ["0","timesTen"], "1" : ["0","moo"] }
//     }
//
func (d *DNode) SendRemote(object interface{}) {
	d.Send("methods", object)
}

// Send serializes the method and arguments, then sends to the SendChan.
// The user is responsible for reading from the channel and sending
// messages to the remote side.
func (d *DNode) Send(method interface{}, arguments ...interface{}) {
	callbacks := make(map[string]([]string))
	d.CollectCallbacks(arguments, make([]string, 0), callbacks)

	rawArgs, err := json.Marshal(arguments)
	if err != nil {
		panic(err)
	}

	message := Message{
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

func (d *DNode) CollectCallbacks(rawObj interface{}, path []string, callbackMap map[string]([]string)) {
	switch obj := rawObj.(type) {
	case nil:
		// skip
	case []interface{}:
		for i, v := range obj {
			d.CollectCallbacks(v, append(path, strconv.Itoa(i)), callbackMap)
		}
	case map[string]interface{}:
		for key, value := range obj {
			v := reflect.ValueOf(value)
			if v.Kind() == reflect.Func {
				d.registerCallback(key, v, path, callbackMap)
				delete(obj, key)
			}
		}
	case *map[string]interface{}:
		for key, value := range *obj {
			v := reflect.ValueOf(value)
			if v.Kind() == reflect.Func {
				d.registerCallback(key, v, path, callbackMap)
				delete(*obj, key)
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

	callbackMap[strconv.Itoa(len(d.Callbacks))] = pathCopy
	d.Callbacks = append(d.Callbacks, callback)
}

// ProcessMessage processes a single message and call the previously
// added callbacks.
func (d *DNode) ProcessMessage(data []byte) {
	var m Message
	err := json.Unmarshal(data, &m)
	if err != nil {
		panic(err)
	}

	// Parse callbacks and create arguments.
	for id, path := range m.Callbacks {
		// methodId in callbacks must be an integer.
		methodId, err := strconv.Atoi(id)
		if err != nil {
			panic(err)
		}

		// Add the callback to arguments.
		callback := Callback(func(args ...interface{}) {
			d.Send(methodId, args...)
		})
		m.Arguments.Callbacks = append(m.Arguments.Callbacks, CallbackSpec{path, callback})
	}

	// Initial methods exchange
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

	// If the method name is an integer, call the function with arguments.
	if index, err := strconv.Atoi(fmt.Sprint(m.Method)); err == nil {
		args, err := m.Arguments.Array()
		if err != nil {
			panic(err)
		}
		if index < 0 || index >= len(d.Callbacks) {
			return
		}
		callArgs := make([]reflect.Value, len(args))
		for i, v := range args {
			callArgs[i] = reflect.ValueOf(v)
		}
		d.Callbacks[index].Call(callArgs)
		return
	}

	if d.OnRootMethod != nil {
		d.OnRootMethod(fmt.Sprint(m.Method), m.Arguments)
		return
	}

	panic(fmt.Sprintf("Unknown method: %v.", m.Method))
}
