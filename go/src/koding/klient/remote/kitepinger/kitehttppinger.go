package kitepinger

import (
	"errors"
	"io/ioutil"
	"net/http"
	"net/url"
	"time"
)

const kiteHTTPResponse = "Welcome to SockJS!\n"

const (
	defaultClientTimeout = time.Second
)

type KiteHTTPPinger struct {
	// Client is the http Client to use for Pinging.
	//
	// If custom timeouts are desired, override the default Client as needed.
	Client *http.Client

	// The http or address
	Address string
}

func NewKiteHTTPPinger(a string) (*KiteHTTPPinger, error) {
	if a == "" {
		return nil, errors.New("NewKiteHTTPPinger: Address is required")
	}

	// Make sure the given address is valid, since Ping() doesn't return an error.
	u, err := url.Parse(a)
	if err != nil {
		return nil, err
	}

	if u.Scheme == "" {
		return nil, errors.New("NewKiteHTTPPinger: Address must contain a scheme")
	}

	if u.Host == "" {
		return nil, errors.New("NewKiteHTTPPinger: Address must contain a host")
	}

	c := &http.Client{
		Timeout: defaultClientTimeout,
	}

	return &KiteHTTPPinger{
		Client:  c,
		Address: a,
	}, nil
}

// Ping the given address for a Kite HTTP server. If the response does not match
// the expected kite response we fail.
func (p *KiteHTTPPinger) Ping() Status {
	res, err := p.Client.Get(p.Address)
	if err != nil {
		return Failure
	}
	defer res.Body.Close()

	resData, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return Failure
	}

	if string(resData) != kiteHTTPResponse {
		return Failure
	}

	return Success
}
