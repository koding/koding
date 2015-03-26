package models

type Client struct {
	Account *Account
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

func (c *Context) IsAdmin() bool {
	if !c.IsLoggedIn() {
		return false
	}

	return IsIn(c.Client.Account.Nick, superAdmins...)
}

var superAdmins = []string{
	"sinan", "devrim", "gokmen", "fatihacet", "arslan",
	"sent-hil", "cihangirsavas", "leeolayvar", "stefanbc",
	"szkl", "canthefason", "nitin", "usirin",
}
