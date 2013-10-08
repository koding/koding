package moh

import (
	"bytes"
	"io/ioutil"
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
func (req *Requester) Request(message []byte) ([]byte, error) {
	resp, err := req.c.Post("http://"+req.addr+"/",
		"application/octet-strem",
		bytes.NewReader(message))
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
