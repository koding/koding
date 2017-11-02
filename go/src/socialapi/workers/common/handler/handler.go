package handler

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"reflect"
	"time"
	"unicode"
	"unicode/utf8"

	"koding/tools/utils"
	"socialapi/models"
	"socialapi/workers/common/response"
	"strconv"
	"strings"

	"koding/db/mongodb/modelhelper"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	kmetrics "github.com/koding/metrics"
	"github.com/koding/runner"
	gometrics "github.com/rcrowley/go-metrics"
	tigertonic "github.com/rcrowley/go-tigertonic"
	mgo "gopkg.in/mgo.v2"
	throttled "gopkg.in/throttled/throttled.v2"
)

const (
	// PostRequest represents a "POST" http request
	PostRequest = "POST"

	// GetRequest represents a "GET" http request
	GetRequest = "GET"

	// DeleteRequest represents a "DELETE" http request
	DeleteRequest = "DELETE"

	// PutRequest represents a "PUT" http request
	PutRequest = "PUT"
)

var (
	// TODO allowed origins must be configurable
	cors       = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
	errGeneric = errors.New("an error occurred")
)

// Request holds constructive info regarding handler creation
type Request struct {
	Handler        interface{}
	Endpoint       string
	Type           string
	Name           string
	CollectMetrics bool
	Metrics        *kmetrics.Metrics

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

	writeJSONError(w, errGeneric)
}

var throttleDenyHandler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	writeJSONError(w, response.LimitRateExceededError{})
})

// getAccount tries to retrieve account information from incoming request,
// should always return a valid account, not nil
func getAccount(r *http.Request, groupName string) *models.Account {
	clientID := getClientID(r)

	// if cookie doenst exists return empty account
	if clientID == "" {
		return models.NewAccount()
	}

	session, err := models.Cache.Session.ById(clientID)
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

// getClientID gets client id from cookie, if fails, returns empty string.
func getClientID(r *http.Request) string {
	cookie, err := r.Cookie("clientId")
	if err == nil {
		return cookie.Value
	}

	auth := r.Header.Get("Authorization")
	if strings.HasPrefix(auth, "Bearer ") {
		return auth[len("Bearer "):]
	}

	return ""
}

// getGroupName tries to get the group name from JSession, if fails to do so,
// returns koding as groupname. This function should allow failures because some of our
func getGroupName(r *http.Request) string {
	const groupName = "koding"

	clientID := getClientID(r)

	// if cookie doenst exists return default group
	if clientID == "" {
		return groupName
	}

	session, err := models.Cache.Session.ById(clientID)
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

	hHandler = tigertonic.Marshaled(handler)

	hHandler = buildHandlerWithTimeTracking(hHandler, r)

	// every request should return under 30 secs, if not return 503 service
	// unavailable
	hHandler = http.TimeoutHandler(hHandler, timeoutDuration, timedOutMsg)

	// set rate limiting if the handler has one
	if r.Ratelimit != nil {
		hHandler = BuildHandlerWithRateLimit(hHandler, r.Ratelimit)
	}

	// create the final handler
	return hHandler
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

func BuildHandlerWithContext(handler http.Handler, log logging.Logger) http.Handler {
	// add context
	return tigertonic.If(
		func(r *http.Request) (http.Header, error) {
			context := models.NewContext(log)
			context.GroupName = getGroupName(r)
			context.Client = &models.Client{
				Account:   getAccount(r, context.GroupName),
				IP:        net.ParseIP(utils.GetIpAddress(r)),
				SessionID: getClientID(r),
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

func writeJSONError(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(errorStatusCode(err))
	if jsonErr := json.NewEncoder(w).Encode(map[string]string{
		"description": err.Error(),
		"error":       errorName(err, "error"),
	}); nil != jsonErr {
		log.Printf("Error marshalling error response into JSON output: %s", jsonErr)
	}
}

func errorStatusCode(err error) int {
	if httpEquivError, ok := err.(tigertonic.HTTPEquivError); ok {
		return httpEquivError.StatusCode()
	}
	return http.StatusInternalServerError
}

func errorName(err error, fallback string) string {
	if namedError, ok := err.(tigertonic.NamedError); ok {
		if name := namedError.Name(); "" != name {
			return name
		}
	}
	if httpEquivError, ok := err.(tigertonic.HTTPEquivError); ok && tigertonic.SnakeCaseHTTPEquivErrors {
		return strings.Replace(
			strings.ToLower(http.StatusText(httpEquivError.StatusCode())),
			" ",
			"_",
			-1,
		)
	}
	t := reflect.TypeOf(err)
	if reflect.Ptr == t.Kind() {
		t = t.Elem()
	}
	if r, _ := utf8.DecodeRuneInString(t.Name()); unicode.IsLower(r) {
		return fallback
	}
	return t.String()
}
