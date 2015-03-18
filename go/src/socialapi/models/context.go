package models

import "net"

type Client struct {
	Account *Account
	IP      net.IP
}

type Context struct {
	GroupName string
	Client    *Client
}

func (c *Context) IsLoggedIn() bool {
	if c.Client == nil {
		return false
	}

	if c.Client.Account == nil {
		return false
	}

	if c.Client.Account.Id == 0 {
		return false
	}

	return true
}
