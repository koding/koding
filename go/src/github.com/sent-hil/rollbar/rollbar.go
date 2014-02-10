// Wrapper around rollbar.com api.
package rollbar

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
)

const v1Endpoint = "https://api.rollbar.com/api/1"

type Client struct {
	HttpClient *http.Client
	Token      string
	Endpoint   *url.URL
}

func NewClient(token string) *Client {
	rel, err := url.Parse(v1Endpoint)
	if err != nil {
		panic(err)
	}

	client := &Client{
		HttpClient: http.DefaultClient,
		Token:      token,
		Endpoint:   rel,
	}

	return client
}

func (c *Client) Request(verb, url string) (io.ReadCloser, error) {
	url = c.BuildUrl(url)

	req, err := http.NewRequest(verb, url, nil)
	if err != nil {
		return nil, err
	}

	resp, err := c.HttpClient.Do(req)
	if err != nil {
		return nil, err
	}

	return resp.Body, nil
}

// Rollbar api has a bug where all urls needs to have an extra slash
// before access token; for example this will return a result:
//    api.rollbar.com/api/1/deploys/?access_token=...
// however this will not:
//    api.rollbar.com/api/1/deploys?access_token=...
// I've emailed them about it on Jan 14, 2014.
func (c *Client) BuildUrl(url string) string {
	return fmt.Sprintf("%v/%v/?access_token=%v", c.Endpoint, url, c.Token)
}
