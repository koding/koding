package models

import (
	"net/url"
	"strconv"
	"time"

	"github.com/kennygrant/sanitize"
)

type Query struct {
	Skip      int
	Limit     int
	To        time.Time
	From      time.Time
	GroupName string
	Type      string
	Privacy   string
	AccountId int64
	Name      string
}

func NewQuery() *Query {
	return &Query{}
}

func (q *Query) MapURL(u *url.URL) *Query {
	urlQuery := u.Query()

	q.Skip, _ = strconv.Atoi(urlQuery.Get("skip"))
	q.Limit, _ = strconv.Atoi(urlQuery.Get("limit"))

	q.Name = u.Query().Get("name")
	if q.Name != "" {
		q.Name = sanitize.Name(q.Name)
	}

	q.GroupName = u.Query().Get("groupName")
	if q.GroupName != "" {
		q.GroupName = sanitize.Name(q.GroupName)
	}

	q.Type = u.Query().Get("type")
	if q.Type != "" {
		q.Type = sanitize.Name(q.Type)
	}

	q.Privacy = u.Query().Get("privacy")
	if q.Privacy != "" {
		q.Privacy = sanitize.Name(q.Privacy)
	}

	q.AccountId, _ = strconv.ParseInt(u.Query().Get("accountId"), 10, 64)

	if to := urlQuery.Get("to"); to != "" {
		q.To, _ = time.Parse(time.RFC3339, to)
	}

	if from := urlQuery.Get("from"); from != "" {
		q.From, _ = time.Parse(time.RFC3339, from)
	}

	return q
}

func (q *Query) SetDefaults() *Query {
	if q.Skip == 0 {
		// no need to do something
	}

	if q.Limit == 0 || q.Limit > 25 {
		q.Limit = 25
	}

	if q.From.IsZero() {
		q.From = time.Now().UTC()
	}

	if q.GroupName == "" {
		q.GroupName = "koding"
	}

	return q
}
