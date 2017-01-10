package client

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/url"
	"socialapi/workers/presence"
	"time"
)

var defaultClient = &http.Client{
	Transport: &http.Transport{
		DialContext: (&net.Dialer{
			Timeout: time.Second,
		}).DialContext,
	},
}

// Client is an http client to send ping requests to internal endpoint.
type Client struct {
	endpoint    string
	requestType string
	reqFunc     func(string, string) (*http.Cookie, io.Reader, error)
	HTTPClient  *http.Client
}

// NewInternal creates a new client for internal ping requests.
func NewInternal(host string) *Client {
	fullURL := host + presence.EndpointPresencePingPrivate
	if _, err := url.ParseRequestURI(fullURL); err != nil {
		panic("url is not valid")
	}

	return &Client{
		endpoint:    fullURL,
		requestType: "POST",
		reqFunc:     internalReqFunc,
		HTTPClient:  defaultClient,
	}
}

// NewPublic creates a new client for public ping requests.
func NewPublic(host string) *Client {
	fullURL := host + presence.EndpointPresencePing
	if _, err := url.ParseRequestURI(fullURL); err != nil {
		panic("url is not valid")
	}

	return &Client{
		endpoint:    fullURL,
		requestType: "GET",
		reqFunc:     publicReqFunc,
		HTTPClient:  defaultClient,
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

	kookie, body, err := c.reqFunc(identifier, groupName)
	if err != nil {
		return nil, err
	}

	r, err := http.NewRequest(c.requestType, c.endpoint, body)
	if err != nil {
		return nil, err
	}
	if kookie != nil {
		r.AddCookie(kookie)
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
func internalReqFunc(username, groupName string) (cookie *http.Cookie, body io.Reader, err error) {
	data, err := json.Marshal(map[string]string{
		"username":  username,
		"groupName": groupName,
	})
	if err != nil {
		return nil, nil, err
	}
	return nil, bytes.NewReader(data), nil
}

func publicReqFunc(token, _ string) (cookie *http.Cookie, body io.Reader, err error) {
	cookie = &http.Cookie{
		Name:  "clientId",
		Value: token,
		// Raw:     "clientId=" + token,
	}
	return cookie, nil, nil
}
