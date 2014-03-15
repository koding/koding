package models

import (
	"net/url"
	"strconv"
	"time"
)

type Query struct {
	Skip      int       //`json:"skip,omitempty"`
	Limit     int       //`json:"limit,omitempty"`
	To        time.Time //`json:"to,omitempty"`
	From      time.Time //`json:"from,omitempty"`
	AccountId int64
}

func NewQuery() *Query {
	return &Query{}
}

func (q *Query) MapURL(u *url.URL) *Query {
	urlQuery := u.Query()

	q.Skip, _ = strconv.Atoi(urlQuery.Get("skip"))
	q.Limit, _ = strconv.Atoi(urlQuery.Get("limit"))
	q.AccountId, _ = strconv.ParseInt(u.Query().Get("accountId"), 10, 64)

	q.To, _ = time.Parse(time.RFC3339, urlQuery.Get("to"))
	q.From, _ = time.Parse(time.RFC3339, urlQuery.Get("from"))

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

	return q
}
