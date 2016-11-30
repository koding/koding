package auth

import (
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/kontrol"
)

var DefaultClient = &Client{}

type LoginOptions struct {
	Team string
}

type Client struct {
	Kloud   *kloud.Client
	Kontrol *kontrol.Client
}

func (c *Client) Login(opts *LoginOptions) error {
	return nil
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func (c *Client) kontrol() *kontrol.Client {
	if c.Kontrol != nil {
		return c.Kontrol
	}
	return kontrol.DefaultClient
}

func Login(opts *LoginOptions) error { return DefaultClient.Login(opts) }
