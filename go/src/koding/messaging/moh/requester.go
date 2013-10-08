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

func NewRequester(addr string) *Requester {
	return &Requester{addr: addr}
}

func (req *Requester) Request(message []byte) ([]byte, error) {
	resp, err := req.c.Post("http://"+addr+"/",
		"application/octet-strem",
		bytes.NewReader(data))
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
