package request

import (
	"math"
	"net/url"
	"strconv"
	"time"

	"github.com/kennygrant/sanitize"
)

const (
	DEFAULT_REPLY_LIMIT = 3
	MAX_REPLY_LIMIT     = 25
	MAX_LIMIT           = 25
)

type Query struct {
	Skip           int       `url:"skip"`
	Limit          int       `url:"limit"`
	To             time.Time `url:"to"`
	From           time.Time `url:"from"`
	GroupName      string    `url:"groupName"`
	GroupChannelId int64     `url:"groupChannelId"`
	Type           string    `url:"type"`
	Privacy        string    `url:"privacy"`
	AccountId      int64     `url:"accountId"`
	Name           string    `url:"name"`
	Slug           string    `url:"slug"`
	ShowExempt     bool      `url:"showExempt"`
	ReplyLimit     int       `url:"replyLimit"`
	ReplySkip      int       `url:"replySkip"`
}

func NewQuery() *Query {
	return &Query{}
}

func (q *Query) MapURL(u *url.URL) *Query {
	urlQuery := u.Query()

	q.Skip, _ = strconv.Atoi(urlQuery.Get("skip"))
	q.Limit, _ = strconv.Atoi(urlQuery.Get("limit"))

	q.Name = urlQuery.Get("name")
	if q.Name != "" {
		q.Name = sanitize.Name(q.Name)
	}

	q.Slug = urlQuery.Get("slug")
	if q.Slug != "" {
		q.Slug = sanitize.Name(q.Slug)
	}

	q.GroupName = urlQuery.Get("groupName")
	if q.GroupName != "" {
		q.GroupName = sanitize.Name(q.GroupName)
	}

	q.Type = urlQuery.Get("type")
	if q.Type != "" {
		q.Type = sanitize.Name(q.Type)
	}

	q.Privacy = urlQuery.Get("privacy")
	if q.Privacy != "" {
		q.Privacy = sanitize.Name(q.Privacy)
	}

	q.AccountId, _ = strconv.ParseInt(urlQuery.Get("accountId"), 10, 64)
	q.GroupChannelId, _ = strconv.ParseInt(urlQuery.Get("groupChannelId"), 10, 64)

	if to := urlQuery.Get("to"); to != "" {
		q.To, _ = time.Parse(time.RFC3339, to)
	}

	if from := urlQuery.Get("from"); from != "" {
		q.From, _ = time.Parse(time.RFC3339, from)
	}

	if showExempt := urlQuery.Get("showExempt"); showExempt != "" {
		isExempt, _ := strconv.ParseBool(showExempt)
		q.ShowExempt = isExempt
	}

	if replyLimit := urlQuery.Get("replyLimit"); replyLimit != "" {
		replyLimit, _ := strconv.Atoi(replyLimit)
		q.ReplyLimit = replyLimit
	}

	if replySkip := urlQuery.Get("replyLimit"); replySkip != "" {
		replySkip, _ := strconv.Atoi(replySkip)
		q.ReplySkip = replySkip
	}

	return q
}

func (q *Query) Clone() *Query {
	cq := NewQuery()
	*cq = *q

	return cq
}

func (q *Query) SetDefaults() *Query {
	if q.Skip == 0 {
		// no need to do something
	}

	if q.Limit == 0 || q.Limit > MAX_LIMIT {
		q.Limit = MAX_LIMIT
	}

	if q.From.IsZero() {
		q.From = time.Now().UTC()
	}

	if q.GroupName == "" {
		q.GroupName = "koding"
	}

	if q.ReplyLimit == 0 {
		q.ReplyLimit = DEFAULT_REPLY_LIMIT
	} else {
		q.ReplyLimit = int(math.Min(float64(q.ReplyLimit), float64(MAX_REPLY_LIMIT)))
	}

	return q
}
