package moh

import (
	"io/ioutil"
	"net/http"
)

type Replier struct {
	CloseableServer
}

func NewReplier(addr string, h Handler) (*Replier, error) {
	s, err := NewClosableServer(addr)
	if err != nil {
		return nil, err
	}

	s.mux.HandleFunc("/", makeHttpHandler(h))
	go s.serve()
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
