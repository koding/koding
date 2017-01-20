package kontrol

import "koding/klientctl/endpoint/kloud"

type RegisterRequest struct {
	AuthType string
	Token    string
}

var DefaultClient = &Client{}

type Client struct {
	Kloud *kloud.Client
}

func (c *Client) Call(method string, req, resp interface{}) error {
	return nil
}
