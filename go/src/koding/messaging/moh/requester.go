package moh

import (
	"bytes"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"time"
)

// Requester is a HTTP client that is used to make requests to Replier.
// Sends "keep-alive" header for persistent connections.
type Requester struct {
	url     *url.URL
	client  http.Client
	Timeout time.Duration
}

// NewRequester returns a pointer to a new Requester struct.
// urlStr argument must be the path of a Replier.
func NewRequester(urlStr string) *Requester {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		panic(err)
	}
	r := &Requester{
		url:     parsed,
		Timeout: DefaultDialTimeout,
	}
	r.client.Transport = &http.Transport{Dial: r.dialTimeout}
	return r
}

func (r *Requester) dialTimeout(network, addr string) (net.Conn, error) {
	return net.DialTimeout(network, addr, r.Timeout)
}

// Request sends a message to a Replier over HTTP.
func (r *Requester) Request(message []byte) ([]byte, error) {
	request, err := http.NewRequest("POST", r.url.String(), bytes.NewReader(message))
	if err != nil {
		return nil, err
	}

	request.Header.Set("Content-Type", "application/octet-strem")
	request.Header.Set("Connection", "Keep-Alive")
	// log.Printf("Doing POST to: %s with body: '%s'\n", r.url, string(message))
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
