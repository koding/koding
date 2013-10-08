package moh

import (
	"io/ioutil"
	"net/http"
)

type Replier struct {
	CloseableServer
}

// NewReplier starts a new HTTP server on addr and returns a pointer to the Replier.
// All request will be replied by the handler function h.
func NewReplier(addr string, h Handler) (*Replier, error) {
	s, err := NewClosableServer(addr)
	if err != nil {
		return nil, err
	}

	s.Mux.HandleFunc("/", makeHttpHandler(h))
	go s.Serve()
	return &Replier{*s}, nil
}

func makeHttpHandler(h Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		defer r.Body.Close()
		body, err := ioutil.ReadAll(r.Body)
		if err != nil {
			panic(err)
		}

		reply := h(body)

		_, err = w.Write(reply)
		if err != nil {
			panic(err)
		}
	}
}
