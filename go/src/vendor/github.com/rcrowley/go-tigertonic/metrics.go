package tigertonic

import (
	"fmt"
	"github.com/rcrowley/go-metrics"
	"net/http"
	"time"
)

// Counter is an http.Handler that counts requests via go-metrics.
type Counter struct {
	metrics.Counter
	handler http.Handler
}

// Counted returns an http.Handler that passes requests to an underlying
// http.Handler and then counts the request via go-metrics.
func Counted(
	handler http.Handler,
	name string,
	registry metrics.Registry,
) *Counter {
	counter := &Counter{
		Counter: metrics.NewCounter(),
		handler: handler,
	}
	if nil == registry {
		registry = metrics.DefaultRegistry
	}
	if err := registry.Register(name, counter); nil != err {
		panic(err)
	}
	return counter
}

// ServeHTTP passes the request to the underlying http.Handler and then counts
// the request via go-metrics.
func (c *Counter) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	c.handler.ServeHTTP(w, r)
	c.Inc(1)
}

// CounterByStatus is an http.Handler that counts responses by their HTTP
// status code via go-metrics.
type CounterByStatus struct {
	counters map[int]metrics.Counter
	handler  http.Handler
}

// CountedByStatus returns an http.Handler that passes requests to an
// underlying http.Handler and then counts the response by its HTTP status code
// via go-metrics.
func CountedByStatus(
	handler http.Handler,
	name string,
	registry metrics.Registry,
) *CounterByStatus {
	if nil == registry {
		registry = metrics.DefaultRegistry
	}
	counters := map[int]metrics.Counter{
		100: metrics.NewCounter(),
		101: metrics.NewCounter(),
		200: metrics.NewCounter(),
		201: metrics.NewCounter(),
		202: metrics.NewCounter(),
		203: metrics.NewCounter(),
		204: metrics.NewCounter(),
		205: metrics.NewCounter(),
		206: metrics.NewCounter(),
		300: metrics.NewCounter(),
		301: metrics.NewCounter(),
		302: metrics.NewCounter(),
		303: metrics.NewCounter(),
		304: metrics.NewCounter(),
		305: metrics.NewCounter(),
		306: metrics.NewCounter(),
		307: metrics.NewCounter(),
		400: metrics.NewCounter(),
		401: metrics.NewCounter(),
		402: metrics.NewCounter(),
		403: metrics.NewCounter(),
		404: metrics.NewCounter(),
		405: metrics.NewCounter(),
		406: metrics.NewCounter(),
		407: metrics.NewCounter(),
		408: metrics.NewCounter(),
		409: metrics.NewCounter(),
		410: metrics.NewCounter(),
		411: metrics.NewCounter(),
		412: metrics.NewCounter(),
		413: metrics.NewCounter(),
		414: metrics.NewCounter(),
		415: metrics.NewCounter(),
		416: metrics.NewCounter(),
		417: metrics.NewCounter(),
		422: metrics.NewCounter(),
		500: metrics.NewCounter(),
		501: metrics.NewCounter(),
		502: metrics.NewCounter(),
		503: metrics.NewCounter(),
		504: metrics.NewCounter(),
		505: metrics.NewCounter(),
	}
	for code, counter := range counters {
		if err := registry.Register(
			fmt.Sprintf("%s-%d", name, code),
			counter,
		); nil != err {
			panic(err)
		}
	}
	return &CounterByStatus{
		counters: counters,
		handler:  handler,
	}
}

// ServeHTTP passes the request to the underlying http.Handler and then counts
// the response by its HTTP status code via go-metrics.
func (c *CounterByStatus) ServeHTTP(w0 http.ResponseWriter, r *http.Request) {
	w := NewTeeHeaderResponseWriter(w0)
	c.handler.ServeHTTP(w, r)
	c.counters[w.StatusCode].Inc(1)
}

// CounterByStatusXX is an http.Handler that counts responses by the first
// digit of their HTTP status code via go-metrics.
type CounterByStatusXX struct {
	counter1xx, counter2xx, counter3xx, counter4xx, counter5xx metrics.Counter
	handler                                                    http.Handler
}

// CountedByStatusXX returns an http.Handler that passes requests to an
// underlying http.Handler and then counts the response by the first digit of
// its HTTP status code via go-metrics.
func CountedByStatusXX(
	handler http.Handler,
	name string,
	registry metrics.Registry,
) *CounterByStatusXX {
	if nil == registry {
		registry = metrics.DefaultRegistry
	}
	c := &CounterByStatusXX{
		counter1xx: metrics.NewCounter(),
		counter2xx: metrics.NewCounter(),
		counter3xx: metrics.NewCounter(),
		counter4xx: metrics.NewCounter(),
		counter5xx: metrics.NewCounter(),
		handler:    handler,
	}
	if err := registry.Register(
		fmt.Sprintf("%s-1xx", name),
		c.counter1xx,
	); nil != err {
		panic(err)
	}
	if err := registry.Register(
		fmt.Sprintf("%s-2xx", name),
		c.counter2xx,
	); nil != err {
		panic(err)
	}
	if err := registry.Register(
		fmt.Sprintf("%s-3xx", name),
		c.counter3xx,
	); nil != err {
		panic(err)
	}
	if err := registry.Register(
		fmt.Sprintf("%s-4xx", name),
		c.counter4xx,
	); nil != err {
		panic(err)
	}
	if err := registry.Register(
		fmt.Sprintf("%s-5xx", name),
		c.counter5xx,
	); nil != err {
		panic(err)
	}
	return c
}

// ServeHTTP passes the request to the underlying http.Handler and then counts
// the response by its HTTP status code via go-metrics.
func (c *CounterByStatusXX) ServeHTTP(w0 http.ResponseWriter, r *http.Request) {
	w := NewTeeHeaderResponseWriter(w0)
	c.handler.ServeHTTP(w, r)
	if w.StatusCode < 200 {
		c.counter1xx.Inc(1)
	} else if w.StatusCode < 300 {
		c.counter2xx.Inc(1)
	} else if w.StatusCode < 400 {
		c.counter3xx.Inc(1)
	} else if w.StatusCode < 500 {
		c.counter4xx.Inc(1)
	} else {
		c.counter5xx.Inc(1)
	}
}

// Timer is an http.Handler that counts requests via go-metrics.
type Timer struct {
	metrics.Timer
	handler http.Handler
}

// Timed returns an http.Handler that starts a timer, passes requests to an
// underlying http.Handler, stops the timer, and updates the timer via
// go-metrics.
func Timed(handler http.Handler, name string, registry metrics.Registry) *Timer {
	timer := &Timer{
		Timer:   metrics.NewTimer(),
		handler: handler,
	}
	if nil == registry {
		registry = metrics.DefaultRegistry
	}
	if err := registry.Register(name, timer); nil != err {
		panic(err)
	}
	return timer
}

// ServeHTTP starts a timer, passes the request to the underlying http.Handler,
// stops the timer, and updates the timer via go-metrics.
func (t *Timer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	defer t.UpdateSince(time.Now())
	t.handler.ServeHTTP(w, r)
}
