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

	"koding/tools/utils"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/response"
	"strings"

	"github.com/PuerkitoBio/throttled"
	"github.com/koding/bongo"
	"github.com/koding/logging"
	kmetrics "github.com/koding/metrics"
	"github.com/koding/redis"
	"github.com/koding/runner"

	tigertonic "github.com/rcrowley/go-tigertonic"

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
	Ratelimit *throttled.Throttler
}

var throttleErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
	runner.MustGetLogger().Error("Throttling error: %s", err)

	writeJSONError(w, genericError)
}

var throttleDenyHandler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	writeJSONError(w, response.LimitRateExceededError{})
})

// todo add prooper logging
func getAccount(r *http.Request) *models.Account {
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

	acc := models.NewAccount()
	// err is ignored intentionally
	err = acc.ByNick(session.Username)
	if err != nil && err != bongo.RecordNotFound {
		runner.MustGetLogger().Error("Err while getting account: %s, err :%s", session.Username, err.Error())
	}

	return acc
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
			// this is an example
			// set group name to context
			//

			context := models.NewContext(redis, log)
			context.GroupName = getGroupName(r)
			context.Client = &models.Client{
				Account: getAccount(r),
				IP:      net.ParseIP(utils.GetIpAddress(r)),
			}

			*(tigertonic.Context(r).(*models.Context)) = *context
			return nil, nil
		},
		handler,
	)
}

func BuildHandlerWithRateLimit(handler http.Handler, t *throttled.Throttler) http.Handler {
	throttled.Error = throttleErrorHandler
	throttled.DefaultDeniedHandler = throttleDenyHandler

	return t.Throttle(handler)
}

func MakeRequest(request *Request) (*http.Response, error) {
	if request.Cookie != "" {
		request.Cookies = parseCookiesToArray(request.Cookie)
	}

	request.Endpoint = prepareQueryString(request.Endpoint, request.Params)

	client := new(http.Client)
	hostname := config.MustGet().CustomDomain.Local
	endpoint := fmt.Sprintf("%s/%s", hostname, request.Endpoint)

	var byteData io.Reader
	if request.Body != nil {
		body, err := json.Marshal(request.Body)
		if err != nil {
			return nil, err
		}
		byteData = bytes.NewReader(body)
	}

	req, err := http.NewRequest(request.Type, endpoint, byteData)
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
