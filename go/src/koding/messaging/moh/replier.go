package moh

import (
	"io/ioutil"
	"net/http"
)

// Replier is the counterpart of Requester.
// It is a HTTP server that responds to HTTP requests with it's handler function.
type Replier struct {
	Handler func([]byte) []byte
	*MessagingServer
}

// NewReplier starts a new HTTP server on addr and returns a pointer to the Replier.
// All request will be replied by the handler function.
func NewReplier(addr string, handler func([]byte) []byte) (*Replier, error) {
	r := &Replier{
		MessagingServer: NewMessagingServer(addr),
		Handler:         handler,
	}
	r.Handle("/", r)
	go r.Serve() // Starts HTTP server
	return r, nil
}

// ServeHTTP implements the http.Handler interface for Replier.
func (rep *Replier) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	defer req.Body.Close()
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		http.Error(w, "Cannot read request body", 500)
		return
	}

	reply := rep.Handler(body)

	_, err = w.Write(reply)
	if err != nil {
		http.Error(w, "Cannot write reply", 500)
		return
	}
}
