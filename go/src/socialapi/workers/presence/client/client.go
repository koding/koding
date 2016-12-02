package client

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/url"
	"socialapi/workers/presence/api"
	"time"
)

// Client is an http client to send ping requests to internal endpoint.
type Client struct {
	endpoint    string
	requestType string
	reqFunc     func(string, string) (string, io.Reader, error)
	HTTPClient  *http.Client
}

// NewInternal creates a new client for internal ping requests.
func NewInternal(host string) *Client {
	fullURL := host + api.EndpointPresencePingPrivate
	if _, err := url.ParseRequestURI(fullURL); err != nil {
		panic("url is not valid")
	}

	return &Client{
		endpoint:    fullURL,
		requestType: "POST",
		reqFunc:     internalReqFunc,
		HTTPClient: &http.Client{
			Transport: &http.Transport{
				// timeout only for dialing, if the remote server is not listening, stop asking earlier.
				Dial: func(network, addr string) (net.Conn, error) {
					return net.DialTimeout(network, addr, time.Second)
				},
			},
		},
	}
}

// Ping sends ping requests to presence backend.
func (c *Client) Ping(identifier, groupName string) error {
	req, err := c.NewRequest(identifier, groupName)
	if err != nil {
		return err
	}

	return c.Do(req)
}

// NewRequest creates a new http.Request
func (c *Client) NewRequest(identifier, groupName string) (*http.Request, error) {
	if identifier == "" {
		return nil, errors.New("identifier must be set")
	}
	if groupName == "" {
		return nil, errors.New("groupName must be set")
	}

	queryString, body, err := c.reqFunc(identifier, groupName)
	if err != nil {
		return nil, err
	}

	r, err := http.NewRequest(c.requestType, c.endpoint+queryString, body)
	if err != nil {
		return nil, err
	}

	r.Header.Set("Accept", "application/json")
	r.Header.Set("Content-Type", "application/json")
	return r, nil
}

// Do send the http.Request
func (c *Client) Do(req *http.Request) error {
	resp, err := c.HTTPClient.Do(req)
	defer func() {
		if resp != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		return err
	}
	if resp.StatusCode > 399 {
		return errors.New("bad response")
	}

	return nil
}
func internalReqFunc(username, groupName string) (queryString string, body io.Reader, err error) {
	data, err := json.Marshal(map[string]string{
		"username":  username,
		"groupName": groupName,
	})
	if err != nil {
		return "", nil, err
	}
	return "", bytes.NewReader(data), nil
}
