package moh

import (
	"io/ioutil"
	"net/http"
)

type Replier struct {
	CloseableServer
}

// NewReplier starts a new HTTP server on addr and returns a pointer to the Replier.
// All request will be replied by the handler function.
func NewReplier(addr string, handler MessageHandler) (*Replier, error) {
	s, err := NewClosableServer(addr)
	if err != nil {
		return nil, err
	}

	s.Mux.HandleFunc("/", makeHttpHandler(handler))
	go s.Serve()
	return &Replier{CloseableServer: *s}, nil
}

func makeHttpHandler(handler MessageHandler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		defer r.Body.Close()
		body, err := ioutil.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Cannot read request body", 500)
			return
		}

		reply := handler(body)

		_, err = w.Write(reply)
		if err != nil {
			http.Error(w, "Cannot write reply", 500)
			return
		}
	}
}
