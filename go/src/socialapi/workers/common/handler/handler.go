package handler

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"time"

	"koding/tools/utils"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/metrics"
	"socialapi/workers/common/response"
	"strconv"
	"strings"

	"github.com/juju/ratelimit"
	kmetrics "github.com/koding/metrics"

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
	cors     = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
	conf     *config.Config
	trackers *metrics.Trackers
)

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
	Ratelimit func(*http.Request) *ratelimit.Bucket
}

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
    acc.ByNick(session.Username)
    
	return acc
}

const timedOutMsg = `{"description":"request timed out","error":"koding.RequestTimedoutError"}`
const timeoutDuration = time.Second * 30

func Wrapper(r Request) http.Handler {
	handler := r.Handler

	var hHandler http.Handler

	// count the statuses of the requests
	hHandler = buildHandlerWithStatusCount(handler, r)

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

// count the statuses of the requests
func buildHandlerWithStatusCount(handler interface{}, r Request) http.Handler {
	return CountedByStatus(
		tigertonic.Marshaled(handler), r.Name, r.CollectMetrics,
	)
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

func BuildHandlerWithContext(handler http.Handler) http.Handler {
	// add context
	return tigertonic.If(
		func(r *http.Request) (http.Header, error) {
			// this is an example
			// set group name to context
			//

			context := &models.Context{
				GroupName: "koding",
				Client: &models.Client{
					Account: getAccount(r),
					IP:      net.ParseIP(utils.GetIpAddress(r)),
				},
			}

			*(tigertonic.Context(r).(*models.Context)) = *context
			return nil, nil
		},
		handler,
	)
}

func BuildHandlerWithRateLimit(handler http.Handler, limiter func(*http.Request) *ratelimit.Bucket) http.Handler {
	// add context
	return tigertonic.If(
		func(r *http.Request) (http.Header, error) {
			// get the limiter
			bucket := limiter(r)

			h := http.Header{}
			h.Add("X-RateLimit-Limit", strconv.FormatInt(int64(bucket.Rate()*60), 10))

			// check if any 		throttling is enabled and then check token's available.
			// Tokens are filled per frequency of the initial bucket, so every request
			// is going to take one token from the bucket. If many requests come in (in
			// span time larger than the bucket's frequency), there will be no token's
			// available more so it will return a zero.
			timeToWait := bucket.Take(1)
			if timeToWait > time.Duration(0) {
				h.Add("Retry-After", strconv.FormatInt(int64(timeToWait.Seconds()), 10))
				return h, &response.LimitRateExceededError{}
			}

			return h, nil
		},
		handler,
	)
}

//----------------------------------------------------------
// CounterByStatus
//----------------------------------------------------------

type CounterByStatus struct {
	name           string
	handler        http.Handler
	collectMetrics bool
}

func (c *CounterByStatus) ServeHTTP(w0 http.ResponseWriter, r *http.Request) {
	w := tigertonic.NewTeeHeaderResponseWriter(w0)
	c.handler.ServeHTTP(w, r)

	if w.StatusCode <= 300 {
		c.track()
	}
}

func (c *CounterByStatus) track() {
	// don't log if analytics are disabled for that endpoint
	if !c.collectMetrics {
		return
	}

	// set `conf` and `trackers` if either is not set
	if conf == nil || trackers == nil {
		conf = config.MustGet()

		// don't log if analytics are disabled globally
		if !conf.Mixpanel.Enabled {
			return
		}

		trackers = metrics.InitTrackers(
			metrics.NewMixpanelTracker(conf.Mixpanel.Token),
		)
	}

	trackers.Track(c.name)
}

func CountedByStatus(handler http.Handler, name string, collectMetrics bool) *CounterByStatus {
	return &CounterByStatus{
		name:           name,
		handler:        handler,
		collectMetrics: collectMetrics,
	}
}

//
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

func ParseCookiesToMap(cookie string) map[string]*http.Cookie {
	pairs := strings.Split(cookie, "; ")
	cookies := make(map[string]*http.Cookie, 0)

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

		cookies[cp[0]] = c
	}

	return cookies
}
