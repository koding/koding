package presence

import (
	"errors"
	"net/http"
	"net/url"

	"koding/socialapi"
)

type Client struct {
	Endpoint *url.URL     // presence endpoint of socialapi
	Client   *http.Client // client with *socialapi.Transport transport
}

func (c *Client) Ping(username, team string) error {
	req, err := http.NewRequest("GET", c.Endpoint.String(), nil)
	if err != nil {
		return err
	}

	req = (&socialapi.Session{
		Username: username,
		Team:     team,
	}).WithRequest(req)

	resp, err := c.Client.Do(req)
	if err != nil {
		return err
	}

	switch resp.StatusCode {
	case http.StatusOK, http.StatusNoContent:
		return nil
	default:
		return errors.New(resp.Status)
	}
}
