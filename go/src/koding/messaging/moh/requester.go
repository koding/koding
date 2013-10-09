package moh

import (
	"bytes"
	"io/ioutil"
	"log"
	"net/http"
)

type Requester struct {
	addr string
	c    http.Client
}

// NewRequester returns a pointer to a new Requester struct.
// addr argument must be the address of a Replier.
func NewRequester(addr string) *Requester {
	return &Requester{addr: addr}
}

// Requester sends a message to a Replier over HTTP.
func (r *Requester) Request(message []byte) ([]byte, error) {
	request, err := http.NewRequest("POST", "http://"+r.addr+"/", bytes.NewReader(message))
	if err != nil {
		return nil, err
	}

	request.Header.Set("Content-Type", "application/octet-strem")
	request.Header.Set("Connection", "Keep-Alive")
	log.Println("Doing POST to: %s", r.addr)
	resp, err := r.c.Do(request)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	reply, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return reply, nil
}
