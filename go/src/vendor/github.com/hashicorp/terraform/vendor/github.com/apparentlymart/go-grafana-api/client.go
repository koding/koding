package gapi

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
)

type Client struct {
	key     string
	baseURL url.URL
	*http.Client
}

//New creates a new grafana client
//auth can be in user:pass format, or it can be an api key
func New(auth, baseURL string) (*Client, error) {
	u, err := url.Parse(baseURL)
	if err != nil {
		return nil, err
	}
	key := ""
	if strings.Contains(auth, ":") {
		split := strings.Split(auth, ":")
		u.User = url.UserPassword(split[0], split[1])
	} else {
		key = fmt.Sprintf("Bearer %s", auth)
	}
	return &Client{
		key,
		*u,
		&http.Client{},
	}, nil
}

func (c *Client) newRequest(method, path string, body io.Reader) (*http.Request, error) {
	url := c.baseURL
	url.Path = path
	req, err := http.NewRequest(method, url.String(), body)
	if err != nil {
		return req, err
	}
	if c.key != "" {
		req.Header.Add("Authorization", c.key)
	}
	if body == nil {
		fmt.Println("request to ", url.String(), "with no body data")
	} else {
		fmt.Println("request to ", url.String(), "with body data", body.(*bytes.Buffer).String())
	}
	req.Header.Add("Content-Type", "application/json")
	return req, err
}
