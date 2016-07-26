package tigertonic

import (
	"net/http"
	"reflect"
	"sync"
)

var (
	contexts map[*http.Request]interface{}
	mutex    sync.Mutex
)

// Context returns the request context as an interface{} given a pointer
// to the request itself.
func Context(r *http.Request) interface{} {
	mutex.Lock()
	defer mutex.Unlock()
	return contexts[r]
}

// ContextHandler is an http.Handler that associates a context object of
// any type with each request it handles.
type ContextHandler struct {
	handler http.Handler
	t       reflect.Type
}

// WithContext wraps an http.Handler and associates a new context object of
// the same type as the second parameter with each request it handles.  You
// must wrap any handler that uses Context or the four-parameter form of
// Marshaled in WithContext.
func WithContext(handler http.Handler, i interface{}) *ContextHandler {
	return &ContextHandler{
		handler: handler,
		t:       reflect.TypeOf(i),
	}
}

// ServeHTTP adds and removes the per-request context and calls the wrapped
// http.Handler in between.
func (ch *ContextHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ch.add(r)
	defer ch.remove(r)
	ch.handler.ServeHTTP(w, r)
}

func (ch *ContextHandler) add(r *http.Request) {
	mutex.Lock()
	defer mutex.Unlock()
	contexts[r] = reflect.New(ch.t).Interface()
}

func (ch *ContextHandler) remove(r *http.Request) {
	mutex.Lock()
	defer mutex.Unlock()
	delete(contexts, r)
}

func init() {
	contexts = make(map[*http.Request]interface{})
}
