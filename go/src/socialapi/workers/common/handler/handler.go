package handler

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"time"

	"gopkg.in/mgo.v2"

	"koding/tools/utils"
	"socialapi/models"
	"socialapi/workers/common/response"
	"strconv"
	"strings"

	"koding/db/mongodb/modelhelper"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	kmetrics "github.com/koding/metrics"
	"github.com/koding/redis"
	"github.com/koding/runner"
	tigertonic "github.com/rcrowley/go-tigertonic"
	"gopkg.in/throttled/throttled.v2"

	gometrics "github.com/rcrowley/go-metrics"
)

const (
	PostRequest   = "POST"
	GetRequest    = "GET"
	DeleteRequest = "DELETE"
)

var (
	// TODO allowed origins must be configurable
	cors         = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
	genericError = errors.New("an error occurred")
)

type Request struct {
	Handler        interface{}
	Endpoint       string
	Type           string
	Name           string
	CollectMetrics bool
	Metrics        *kmetrics.Metrics

	// Securer holds the secure functions for handlers
	Securer interface{}

	// used for external requests
	Params    map[string]string
	Cookie    string
	Cookies   []*http.Cookie
	Body      interface{}
	Headers   map[string]string
	Ratelimit *throttled.HTTPRateLimiter
}

var throttleErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
	runner.MustGetLogger().Error("Throttling error: %s", err)

	writeJSONError(w, genericError)
}

var throttleDenyHandler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	writeJSONError(w, response.LimitRateExceededError{})
})

// getAccount tries to retrieve account information from incoming request,
// should always return a valid account, not nil
func getAccount(r *http.Request, groupName string) *models.Account {
	cookie, err := r.Cookie("clientId")
	if err != nil {
		return models.NewAccount()
	}

	// if cookie doenst exists return empty account
	if cookie.Value == "" {
		return models.NewAccount()
	}

	session, err := models.Cache.Session.ById(cookie.Value)
	if err != nil {
		return models.NewAccount()
	}

	// if session doesnt have username, return empty account
	if session.Username == "" {
		return models.NewAccount()
	}

	acc, err := makeSureAccount(groupName, session.Username)
	if err != nil {
		if err != bongo.RecordNotFound && err != mgo.ErrNotFound {
			runner.MustGetLogger().Error("Err while getting account: %s, err :%s", session.Username, err.Error())
		}

		return models.NewAccount()
	}

	groupChannel, err := models.Cache.Channel.ByGroupName(groupName)
	if err != nil {
		if err != bongo.RecordNotFound && err != models.ErrGroupNotFound {
			runner.MustGetLogger().Error("Err while getting group channel: %s, err :%s", groupName, err.Error())

			return models.NewAccount()
		}

		// for creating the group channel for the first time, we should not return
		// here with empty account
		return acc
	}

	if err := makeSureMembership(groupChannel, acc.Id); err != nil {
		runner.MustGetLogger().Error("Err while making sure account: %s, err :%s", groupName, err.Error())
		return models.NewAccount()
	}

	return acc
}

// makeSureAccount checks if incoming account is in postgres, if not creates it
// lazily and sets socialapi id of it in mongo
func makeSureAccount(groupName string, username string) (*models.Account, error) {
	// try to fetch account from postgres
	acc := models.NewAccount()
	err := acc.ByNick(username)
	if err == nil {
		return acc, nil
	}

	if err != bongo.RecordNotFound {
		return acc, err
	}

	// if account is not in postgres, try to create it

	// we need account first
	macc, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	acc = models.NewAccount() // account is nil, set it
	acc.OldId = macc.Id.Hex()
	acc.Nick = username
	if err := acc.Create(); err != nil {
		return nil, err
	}

	// set it to cache, in case we may need it
	if err := models.Cache.Account.SetToCache(acc); err != nil {
		return nil, err
	}

	// we just created the account in postgres, so update mongo with
	// socialApiId
	s := modelhelper.Selector{
		"profile.nickname": username,
	}
	o := modelhelper.Selector{"$set": modelhelper.Selector{
		"socialApiId": strconv.FormatInt(acc.Id, 10),
	}}
	if err := modelhelper.UpdateAccount(s, o); err != nil {
		return nil, err
	}

	return acc, nil
}

// makeSureMembership checks if the incoming account is a member of the group
// channel that is persisted within incoming session data
func makeSureMembership(groupChannel *models.Channel, accountId int64) error {
	isMember, err := models.Cache.Participant.ByChannelIdAndAccountId(groupChannel.Id, accountId)
	if err != nil {
		return err
	}
	// we dont need to do anything if the user is a member of group channel
	if isMember {
		return nil
	}

	_, err = groupChannel.AddParticipant(accountId)
	if err != nil && err != models.ErrAccountIsAlreadyInTheChannel {
		return err
	}

	return models.Cache.Participant.SetToCache(groupChannel.Id, accountId)
}

func getGroupName(r *http.Request) string {
	const groupName = "koding"

	cookie, err := r.Cookie("clientId")
	if err != nil {
		return groupName
	}

	// if cookie doenst exists return empty account
	if cookie.Value == "" {
		return groupName
	}

	session, err := models.Cache.Session.ById(cookie.Value)
	if err != nil {
		return groupName
	}

	if session.GroupName == "" {
		return groupName
	}

	return session.GroupName
}

const timedOutMsg = `{"description":"request timed out","error":"koding.RequestTimedoutError"}`
const timeoutDuration = time.Second * 30

func Wrapper(r Request) http.Handler {
	handler := r.Handler

	var hHandler http.Handler

	if r.Securer != nil {
		hHandler = Secure(handler, r.Securer, r.Name)
	} else {
		hHandler = tigertonic.Marshaled(handler)
	}

	hHandler = buildHandlerWithTimeTracking(hHandler, r)

	// every request should return under 30 secs, if not return 503 service
	// unavailable
	hHandler = http.TimeoutHandler(hHandler, timeoutDuration, timedOutMsg)

	// set rate limiting if the handler has one
	if r.Ratelimit != nil {
		hHandler = BuildHandlerWithRateLimit(hHandler, r.Ratelimit)
	}

	// create the final handler
	return cors.Build(hHandler)
}

// add request time tracking
func buildHandlerWithTimeTracking(handler http.Handler, r Request) http.Handler {
	var registry gometrics.Registry

	if r.Metrics != nil {
		registry = r.Metrics.Registry
	}

	return tigertonic.Timed(
		handler,
		r.Name,
		registry,
	)
}

func BuildHandlerWithContext(handler http.Handler, redis *redis.RedisSession, log logging.Logger) http.Handler {
	// add context
	return tigertonic.If(
		func(r *http.Request) (http.Header, error) {
			context := models.NewContext(redis, log)
			context.GroupName = getGroupName(r)
			context.Client = &models.Client{
				Account: getAccount(r, context.GroupName),
				IP:      net.ParseIP(utils.GetIpAddress(r)),
			}

			*(tigertonic.Context(r).(*models.Context)) = *context
			return nil, nil
		},
		handler,
	)
}

func BuildHandlerWithRateLimit(handler http.Handler, t *throttled.HTTPRateLimiter) http.Handler {
	t.Error = throttleErrorHandler
	t.DeniedHandler = throttleDenyHandler

	return t.RateLimit(handler)
}

func DoRequest(request *Request) (*http.Response, error) {
	if request.Cookie != "" {
		request.Cookies = parseCookiesToArray(request.Cookie)
	}

	request.Endpoint = prepareQueryString(request.Endpoint, request.Params)

	client := new(http.Client)

	var byteData io.Reader
	if request.Body != nil {
		body, err := json.Marshal(request.Body)
		if err != nil {
			return nil, err
		}
		byteData = bytes.NewReader(body)
	}

	req, err := http.NewRequest(request.Type, request.Endpoint, byteData)
	req = prepareHeaders(req, request.Headers)

	if err != nil {
		return nil, err
	}

	// Add cookies
	for _, cookie := range request.Cookies {
		req.AddCookie(cookie)
	}

	return client.Do(req)
}

func prepareQueryString(endpoint string, params map[string]string) string {
	if len(params) == 0 {
		return endpoint
	}

	fullPath := fmt.Sprintf("%s?", endpoint)

	for key, value := range params {
		fullPath = fmt.Sprintf("%s%s=%s&", fullPath, key, value)
	}

	return fullPath[0 : len(fullPath)-1]
}

func prepareHeaders(req *http.Request, headers map[string]string) *http.Request {
	newReq := new(http.Request)
	newReq = newReq
	*newReq = *req
	for k, v := range headers {
		newReq.Header.Set(k, v)
	}

	return newReq
}

func parseCookiesToArray(cookie string) []*http.Cookie {
	pairs := strings.Split(cookie, "; ")
	cookies := make([]*http.Cookie, 0)

	if len(pairs) == 0 {
		return cookies
	}

	for _, val := range pairs {
		cp := strings.Split(val, "=")
		if len(cp) != 2 {
			continue
		}

		c := new(http.Cookie)
		c.Name = cp[0]
		c.Value = cp[1]

		cookies = append(cookies, c)
	}

	return cookies
}
