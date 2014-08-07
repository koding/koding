package request

import (
	"math"
	"net/url"
	"path"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/kennygrant/sanitize"
)

const (
	DEFAULT_REPLY_LIMIT = 3
	MAX_REPLY_LIMIT     = 25
	MAX_LIMIT           = 25
)

type Query struct {
	Id              int64     `url:"id,omitempty"`
	Skip            int       `url:"skip"`
	Limit           int       `url:"limit"`
	To              time.Time `url:"to"`
	From            time.Time `url:"from"`
	GroupName       string    `url:"groupName"`
	GroupChannelId  int64     `url:"groupChannelId"`
	Type            string    `url:"type"`
	Privacy         string    `url:"privacy"`
	AccountId       int64     `url:"accountId"`
	AccountNickname string    `url:"accountNickname"`
	Name            string    `url:"name"`
	Slug            string    `url:"slug"`
	ShowExempt      bool      `url:"showExempt"`
	ReplyLimit      int       `url:"replyLimit"`
	ReplySkip       int       `url:"replySkip"`
	AddIsInteracted bool      `url:"addIsInteracted"`
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
		q.Name = escapeString(q.Name)
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

	q.Id, _ = GetURIInt64(u, "id")
	q.AccountId, _ = GetURIInt64(u, "accountId")

	q.AccountNickname = urlQuery.Get("accountNickname")
	if q.AccountNickname != "" {
		q.AccountNickname = sanitize.Name(q.AccountNickname)
	}

	q.GroupChannelId, _ = GetURIInt64(u, "groupChannelId")

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

	if addIsInteracted := urlQuery.Get("addIsInteracted"); addIsInteracted != "" {
		addIsInteracted, _ := strconv.ParseBool(addIsInteracted)
		q.AddIsInteracted = addIsInteracted
	}

	if replyLimit := urlQuery.Get("replyLimit"); replyLimit != "" {
		replyLimit, _ := strconv.Atoi(replyLimit)
		q.ReplyLimit = replyLimit
	}

	if replySkip := urlQuery.Get("replySkip"); replySkip != "" {
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

	q.AddIsInteracted = true

	return q
}

// Sanitize method is taken from "github.com/kennygrant/sanitize" package.
// Removed toLowerCase call from Name method in that package.
func escapeString(text string) string {
	fileName := path.Clean(path.Base(text))
	fileName = strings.Trim(fileName, " ")

	// Replace certain joining characters with a dash
	seps, err := regexp.Compile(`[ &_=+:]`)
	if err == nil {
		fileName = seps.ReplaceAllString(fileName, "-")
	}

	// Remove all other unrecognised characters - NB we do allow any printable characters
	legal, err := regexp.Compile(`[^[:alnum:]-.]`)
	if err == nil {
		fileName = legal.ReplaceAllString(fileName, "")
	}

	// Remove any double dashes caused by existing - in name
	fileName = strings.Replace(fileName, "--", "-", -1)

	// NB this may be of length 0, caller must check
	return fileName
}
