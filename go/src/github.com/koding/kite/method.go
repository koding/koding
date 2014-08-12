package kite

import "sync"

// MethodHandling defines how to handle chaining of kite.Handler middlewares.
// An error breaks the chain regardless of what handling is used. Note that all
// Pre and Post handlers are executed regardless the handling logic, only the
// return paramater is defined by the handling mode.
type MethodHandling int

const (
	// ReturnMethod returns main method's response. This is the standard default.
	ReturnMethod MethodHandling = iota

	// ReturnFirst returns the first non-nil response.
	ReturnFirst

	// ReturnLatest returns the latest response (waterfall behaviour)
	ReturnLatest
)

// Objects implementing the Handler interface can be registered to a method.
// The returned result must be marshalable with json package.
type Handler interface {
	ServeKite(*Request) (result interface{}, err error)
}

// HandlerFunc is a type adapter to allow the use of ordinary functions as
// Kite handlers. If h is a function with the appropriate signature,
// HandlerFunc(h) is a Handler object that calls h.
type HandlerFunc func(*Request) (result interface{}, err error)

// ServeKite calls h(r)
func (h HandlerFunc) ServeKite(r *Request) (interface{}, error) {
	return h(r)
}

// Method defines a method and the Handler it is bind to. By default
// "ReturnMethod" handling is used.
type Method struct {
	// name is the method name. Unnamed methods can exist
	name string

	// handler contains the related Handler for the given method
	handler      Handler   // handler is the base handler, the response of it is returned as the final
	preHandlers  []Handler // a list of handlers that are executed before the main handler
	postHandlers []Handler // a list of handlers that are executed after the main handler

	// authenticate defines if a given authenticator function is enabled for
	// the given auth type in the request.
	authenticate bool

	// handling defines how to handle chaining of kite.Handler middlewares.
	handling MethodHandling

	mu sync.Mutex // protects handler slices
}

// addHandle is an internal method to add a handler
func (k *Kite) addHandle(method string, handler Handler) *Method {
	authenticate := true
	if k.Config.DisableAuthentication {
		authenticate = false
	}

	m := &Method{
		name:         method,
		handler:      handler,
		preHandlers:  k.preHandlers,
		postHandlers: k.postHandlers,
		authenticate: authenticate,
		handling:     k.MethodHandling,
	}

	k.handlers[method] = m
	return m
}

// DisableAuthentication disables authentication check for this method.
func (m *Method) DisableAuthentication() *Method {
	m.authenticate = false
	return m
}

// PreHandler adds a new kite handler which is executed before the method.
func (m *Method) PreHandle(handler Handler) *Method {
	m.preHandlers = append(m.preHandlers, handler)
	return m
}

// PreHandlerFunc adds a new kite handlerfunc which is executed before the
// method.
func (m *Method) PreHandleFunc(handler HandlerFunc) *Method {
	return m.PreHandle(handler)
}

// PostHandle adds a new kite handler which is executed after the method.
func (m *Method) PostHandle(handler Handler) *Method {
	m.postHandlers = append(m.postHandlers, handler)
	return m
}

// PostHandlerFunc adds a new kite handlerfunc which is executed before the
// method.
func (m *Method) PostHandleFunc(handler HandlerFunc) *Method {
	return m.PostHandle(handler)
}

// Handle registers the handler for the given method. The handler is called
// when a method call is received from a Kite.
func (k *Kite) Handle(method string, handler Handler) *Method {
	return k.addHandle(method, handler)
}

// HandleFunc registers a handler to run when a method call is received from a
// Kite. It returns a *Method option to further modify certain options on a
// method call
func (k *Kite) HandleFunc(method string, handler HandlerFunc) *Method {
	return k.addHandle(method, handler)
}

// PreHandle registers an handler which is executed before a kite.Handler
// method is executed. Calling PreHandle multiple times registers multiple
// handlers. A non-error return triggers the execution of the next handler. The
// execution order is FIFO.
func (k *Kite) PreHandle(handler Handler) {
	k.preHandlers = append(k.preHandlers, handler)
}

// PreHandleFunc is the same as PreHandle. It accepts a HandlerFunc.
func (k *Kite) PreHandleFunc(handler HandlerFunc) {
	k.PreHandle(handler)
}

// PostHandle registers an handler which is executed after a kite.Handler
// method is executed. Calling PostHandler multiple times registers multiple
// handlers. A non-error return triggers the execution of the next handler. The
// execution order is FIFO.
func (k *Kite) PostHandle(handler Handler) {
	k.postHandlers = append(k.postHandlers, handler)
}

// PostHandleFunc is the same as PostHandle. It accepts a HandlerFunc.
func (k *Kite) PostHandleFunc(handler HandlerFunc) {
	k.PostHandle(handler)
}

func (m *Method) ServeKite(r *Request) (interface{}, error) {
	var firstResp interface{}
	var resp interface{}
	var err error

	m.mu.Lock()
	defer m.mu.Unlock()

	// first execute preHandlers
	for _, handler := range m.preHandlers {
		resp, err = handler.ServeKite(r)
		if err != nil {
			return nil, err
		}

		if m.handling == ReturnFirst && resp != nil && firstResp == nil {
			firstResp = resp
		}
	}

	// now call our base handler
	resp, err = m.handler.ServeKite(r)
	if err != nil {
		return nil, err
	}

	// also save it dependent on the handling mechanism
	methodResp := resp

	if m.handling == ReturnFirst && resp != nil && firstResp == nil {
		firstResp = resp
	}

	// and finally return our postHandlers
	for _, handler := range m.postHandlers {
		resp, err = handler.ServeKite(r)
		if err != nil {
			return nil, err
		}

		if m.handling == ReturnFirst && resp != nil && firstResp == nil {
			firstResp = resp
		}
	}

	switch m.handling {
	case ReturnMethod:
		return methodResp, nil
	case ReturnFirst:
		return firstResp, nil
	case ReturnLatest:
		return resp, nil
	}

	return resp, nil
}
