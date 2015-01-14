package handler

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/metrics"
	"strings"

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
	Params  map[string]string
	Cookie  string
	Cookies []*http.Cookie
	Body    interface{}
	Headers map[string]string
}

// todo add prooper logging
func getAccount(r *http.Request) *models.Account {
	cookie, err := r.Cookie("clientId")
	if err != nil {
		return nil
	}

	// if cookie doenst exists return nil
	if cookie.Value == "" {
		return nil
	}

	session, err := models.Cache.Session.ById(cookie.Value)
	if err != nil {
		return nil
	}

	if strings.Contains(session.Username, "guest-") {
		session.Username = "guestuser"
	}

	// if session doesnt have username, return nil
	if session.Username == "" {
		return nil
	}

	acc, err := models.Cache.Account.ByNick(session.Username)
	if err != nil {
		return nil
	}

	return acc
}

func Wrapper(r Request) http.Handler {
	handler := r.Handler

	var hHandler http.Handler

	// count the statuses of the requests
	hHandler = buildHandlerWithStatusCount(handler, r)

	hHandler = buildHandlerWithTimeTracking(hHandler, r)

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
				},
			}

			*(tigertonic.Context(r).(*models.Context)) = *context
			return nil, nil
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
	hostname := config.MustGet().CustomDomain.Public
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
