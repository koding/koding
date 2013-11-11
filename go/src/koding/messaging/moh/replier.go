package moh

import (
	"io/ioutil"
	"net/http"
)

// Replier is the counterpart of Requester.
// It is a HTTP server that responds to HTTP requests with it's handler function.
type Replier struct {
	Handler ReplierHandler
}

type ReplierHandler func(*http.Request, []byte) ([]byte, error)

// NewReplier starts a new HTTP server on addr and returns a pointer to the Replier.
// All request will be replied by the handler function.
func NewReplier(handler ReplierHandler) *Replier {
	return &Replier{Handler: handler}
}

// ServeHTTP implements the http.Handler interface for Replier.
func (r *Replier) ServeHTTP(w http.ResponseWriter, request *http.Request) {
	defer request.Body.Close()
	body, err := ioutil.ReadAll(request.Body)
	if err != nil {
		http.Error(w, "Cannot read request body", 500)
		return
	}

	reply, err := r.Handler(request, body)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}

	w.Write(reply)
}
