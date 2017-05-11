package countly

import (
	"encoding/json"
	"net/http"
	"net/url"
	"strings"
)

type Client struct {
	defaultClient *http.Client
	token         string
	baseURL       string
}

// Option is a type for Client options to pass while creating client
type Option func(*Client)

var (
	defaultDomainURL = ""
)

// New initializes the countly api client with given token and option parameters
func New(apiKey string, opts ...Option) *Client {
	if apiKey == "" {
		panic("invalid api token")
	}

	client := &Client{
		defaultClient: &http.Client{},
		token:         apiKey,
		baseURL:       defaultDomainURL,
	}

	for _, option := range opts {
		option(client)
	}

	return client
}

// SetBaseURL sets the url option for Client struct
func SetBaseURL(url string) Option {
	return func(c *Client) {
		c.baseURL = url
	}
}

var defaultClient = &http.Client{}

func (c *Client) do(method, path string, values url.Values, v interface{}) error {
	u := c.createURL(path, values)
	req, err := http.NewRequest(method, u.String(), nil)
	if err != nil {
		return err
	}

	resp, err := c.defaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return json.NewDecoder(resp.Body).Decode(&v)
}

func (c *Client) createURL(path string, values url.Values) *url.URL {
	uri := c.baseURL
	if strings.HasSuffix(uri, "/") {
		uri = uri[:len(uri)-1]
	}

	u, err := url.Parse(uri + path)
	if err != nil {
		return nil
	}

	return addURLValues(u, values)
}

func addURLValues(u *url.URL, values url.Values) *url.URL {
	q := u.Query()
	for key, value := range values {
		for _, v := range value {
			q.Add(key, v)
		}
	}

	u.RawQuery = q.Encode()

	return u
}
