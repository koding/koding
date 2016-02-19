package models

import (
	"net"
	"socialapi/request"

	"github.com/koding/logging"
	"github.com/koding/redis"
)

// Client holds the contextual requester/client info
type Client struct {
	// Account holds the requester info
	Account *Account

	// IP is remote IP of the requester
	IP net.IP

	// SessionID is session cookie id
	SessionID string
}

// Context holds contextual info regarding a REST query
type Context struct {
	GroupName string
	Client    *Client
	redis     *redis.RedisSession
	log       logging.Logger
}

// NewContext creates a new context
func NewContext(redis *redis.RedisSession, log logging.Logger) *Context {
	return &Context{
		redis: redis,
		log:   log,
	}
}

// OverrideQuery overrides Query with context info
func (c *Context) OverrideQuery(q *request.Query) *request.Query {
	// get group name from context
	q.GroupName = c.GroupName
	if c.IsLoggedIn() {
		q.AccountId = c.Client.Account.Id
	} else {
		q.AccountId = 0
	}

	return q
}

// IsLoggedIn checks if the request is an authenticated one
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

// MustGetLogger gets the logger from context, otherwise panics
func (c *Context) MustGetLogger() logging.Logger {
	if c.log == nil {
		panic(ErrLoggerNotExist)
	}

	return c.log
}

// MustGetRedisConn gets the logger from context, otherwise panics
func (c *Context) MustGetRedisConn() *redis.RedisSession {
	if c.redis == nil {
		panic(ErrRedisNotExist)
	}

	return c.redis
}

// c/p from account.coffee
var superAdmins = []string{
	"sinan", "devrim", "gokmen", "fatihacet", "arslan",
	"sent-hil", "cihangirsavas", "leeolayvar", "stefanbc",
	"szkl", "nitin", "usirin",
}
