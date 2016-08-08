// Package mocking makes testing Tiger Tonic services easier.
package mocking

import (
	"fmt"
	"github.com/rcrowley/go-tigertonic"
	"net/http"
	"net/url"
)

// Header augments an optional existing http.Header with Accept and
// Content-Type headers as required by Tiger Tonic.
func Header(h http.Header) http.Header {
	h0 := make(http.Header)
	h0.Add("Accept", "application/json")
	h0.Add("Content-Type", "application/json")
	if nil != h {
		for key, values := range h {
			for _, value := range values {
				h0.Add(key, value)
			}
		}
	}
	return h0
}

// TestableHandler wraps the Handler method from http.ServeMux to make it
// easier to detect in tests.
type TestableHandler interface {
	Handler(*http.Request) (http.Handler, string)
}

// URL constructs a url.URL for use in tests and ensures it's routed by the
// given TestableHandler.
func URL(h TestableHandler, method, rawurl string) *url.URL {
	u, err := url.ParseRequestURI(rawurl)
	if nil != err {
		panic(err)
	}
	if nil != h {
		rq := &http.Request{
			Method: method,
			URL:    u,
		}
		var ok bool
		for {
			h1, _ := h.Handler(rq)
			if _, ok := h1.(tigertonic.NotFoundHandler); ok {
				panic(fmt.Errorf("tigertonic.mocking.URL: No handler found: %s %s", method, rawurl))
			}
			if _, ok := h1.(tigertonic.MethodNotAllowedHandler); ok {
				panic(fmt.Errorf("tigertonic.mocking.URL: Method not allowed: %s %s", method, rawurl))
			}
			if h, ok = h1.(TestableHandler); !ok {
				break
			}
		}
	}
	return u
}
