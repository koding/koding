package moh

import (
	"bytes"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
)

// Requester is a HTTP client that is used to make requests to Replier.
// Sends "keep-alive" header for persistent connections.
type Requester struct {
	url    *url.URL
	client http.Client
}

// NewRequester returns a pointer to a new Requester struct.
// addr argument must be the address of a Replier.
func NewRequester(urlStr string) (*Requester, error) {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		return nil, err
	}
	return &Requester{url: parsed}, nil
}

// Request sends a message to a Replier over HTTP.
func (r *Requester) Request(message []byte) ([]byte, error) {
	request, err := http.NewRequest("POST", r.url.String(), bytes.NewReader(message))
	if err != nil {
		return nil, err
	}

	request.Header.Set("Content-Type", "application/octet-strem")
	request.Header.Set("Connection", "Keep-Alive")
	log.Println("Doing POST to: %s", r.url)
	resp, err := r.client.Do(request)
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
