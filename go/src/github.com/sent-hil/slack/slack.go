// Wrapper around slack.com api.
package slack

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
)

//const v1Endpoint = "https://koding.slack.com"
const v1Endpoint = "https://slack.com"

type Client struct {
	HttpClient *http.Client
	Token      string
	Endpoint   *url.URL
}

func NewClient(token string) *Client {
	var rel, err = url.Parse(v1Endpoint)
	if err != nil {
		panic(err)
	}

	var client = &Client{
		HttpClient: http.DefaultClient,
		Token:      token,
		Endpoint:   rel,
	}

	return client
}

func (c *Client) Request(verb, url string, body interface{}) (io.ReadCloser, error) {
	url = c.BuildUrl(url)
	var req, err = http.NewRequest(verb, url, nil)
	if err != nil {
		return nil, err
	}

	resp, err := c.HttpClient.Do(req)
	if err != nil {
		return nil, err
	}

	return resp.Body, nil
}

func (c *Client) BuildUrl(url string) string {
	return fmt.Sprintf("%v/%v&token=%v&pretty=1", c.Endpoint, url, c.Token)
}
