package discover

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"path"
	"time"

	"github.com/koding/logging"

	"koding/httputil"
)

var defaultHTTPClient = httputil.NewClient(&httputil.ClientConfig{
	DialTimeout:           10 * time.Second,
	RoundTripTimeout:      60 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ResponseHeaderTimeout: 60 * time.Second,
	KeepAlive:             30 * time.Second,
})

var defaultLog = logging.NewCustom("discover", false)

type Endpoint struct {
	Addr     string `json:"addr"`
	Protocol string `json:"protocol"`
	Local    bool   `json:"local"`
}

type Endpoints []*Endpoint

func (e Endpoints) Filter(fn FilterFunc) (res Endpoints) {
	for _, e := range e {
		if fn(e) {
			res = append(res, e)
		}
	}

	return res
}

var (
	ErrServiceNotFound = errors.New("given service was not found")
	ErrNoEndpoints     = errors.New("given service has no endpoints")
	ErrNoTunnel        = errors.New("given addr is not a tunnel")
)

type Client struct {
	HTTPClient *http.Client
	Log        logging.Logger
}

func NewClient() *Client {
	return &Client{}
}

func (c *Client) httpClient() *http.Client {
	if c.HTTPClient != nil {
		return c.HTTPClient
	}

	return defaultHTTPClient
}

func (c *Client) log() logging.Logger {
	if c.Log != nil {
		return c.Log
	}

	return defaultLog
}

func (c *Client) Discover(addr, service string) (Endpoints, error) {
	log := c.log().New("addr", addr, "service", service)

	if net.ParseIP(addr) != nil {
		log.Debug("%s", ErrNoTunnel)

		return nil, ErrNoTunnel
	}

	u, err := url.Parse(addr)
	if err != nil || u.Path == addr {
		u = &url.URL{
			Scheme: "http",
			Host:   addr,
		}
	}
	u.Path = path.Join("/-/discover", service)

	resp, err := c.httpClient().Get(u.String())
	if err != nil {
		log.Error("%s", err)

		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusBadRequest {
		if p, e := ioutil.ReadAll(resp.Body); e == nil && len(p) != 0 {
			err = errors.New(string(p))
		} else {
			err = errors.New("invalid service: " + service)
		}

		log.Error("%s", err)

		return nil, err
	}

	if resp.StatusCode != 200 {
		log.Error(resp.Status)

		return nil, errors.New(http.StatusText(resp.StatusCode))
	}

	var e Endpoints
	if err := json.NewDecoder(resp.Body).Decode(&e); err != nil {
		log.Error("%s", err)

		return nil, err
	}

	if len(e) == 0 {
		log.Error("%s", ErrNoEndpoints)

		return nil, ErrNoEndpoints
	}

	return e, nil
}
