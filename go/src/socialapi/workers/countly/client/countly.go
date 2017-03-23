package client

import (
	"encoding/json"
	"errors"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"

	"github.com/koding/logging"
)

const (
	// this is just an arbitrary number, one can increase it in case of an issue
	maxBody          = 4 << 20
	defaultDomainURL = "http://localhost:32768"
)

// Client holds required properties for communicating with a countly api.
type Client struct {
	httpClient *http.Client
	token      string
	baseURL    string
	log        logging.Logger
}

// Option is a type for Client options to pass while creating client
type Option func(*Client)

// New initializes the countly api client with given token and option parameters
func New(apiKey string, opts ...Option) *Client {
	if apiKey == "" {
		panic("api token is required")
	}

	client := &Client{
		httpClient: http.DefaultClient,
		token:      apiKey,
		baseURL:    defaultDomainURL,
	}

	for _, option := range opts {
		option(client)
	}

	if client.log == nil {
		client.log = logging.NewCustom("countly client", false)
	}

	return client
}

// SetBaseURL sets the url option for Client struct
func SetBaseURL(url string) Option {
	return func(c *Client) {
		c.baseURL = strings.TrimSuffix(url, "/")
	}
}

// SetClient sets the client  option for Client struct
func SetClient(cl *http.Client) Option {
	return func(c *Client) {
		c.httpClient = cl
	}
}

// SetLogger sets the logger option for Client
func SetLogger(log logging.Logger) Option {
	return func(c *Client) {
		c.log = log
	}
}

func (c *Client) do(method, path string, values url.Values, v interface{}) error {
	u := c.createURL(path, values)
	c.log.Debug("url for request %s", u.String())

	req, err := http.NewRequest(method, u.String(), nil)
	if err != nil {
		return err
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	b, err := ioutil.ReadAll(io.LimitReader(resp.Body, maxBody))
	if err != nil {
		return err
	}
	c.log.Debug("response for req %q", string(b))

	if resp.StatusCode != http.StatusOK {
		message := "status: " + resp.Status + " response: " + string(b)
		return errors.New(message)
	}
	if v == nil {
		return nil
	}
	return json.Unmarshal(b, &v)
}

func (c *Client) createURL(path string, values url.Values) *url.URL {
	u, err := url.Parse(c.baseURL + path)
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

func mustAddArgs(values url.Values, args interface{}) url.Values {
	data, err := json.Marshal(args)
	if err != nil {
		panic(err)
	}
	values.Add("args", string(data))
	return values
}
