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

// IsAdmin checks if the current requester is an admin or not, this part is just
// a stub and temproray solution for moderation security, when we implement the
// permission system fully, this should be the first function to remove.
func (c *Context) IsAdmin() bool {
	if !c.IsLoggedIn() {
		return false
	}

	return IsIn(c.Client.Account.Nick, superAdmins...)
}

// c/p from account.coffee
var superAdmins = []string{
	"sinan", "devrim", "gokmen", "fatihacet", "arslan",
	"sent-hil", "cihangirsavas", "leeolayvar", "stefanbc",
	"szkl", "canthefason", "nitin", "usirin",
}
