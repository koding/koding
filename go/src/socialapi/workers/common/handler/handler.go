package handler

import (
	"net/http"

	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/metrics"

	kmetrics "github.com/koding/metrics"

	tigertonic "github.com/rcrowley/go-tigertonic"

	gometrics "github.com/rcrowley/go-metrics"
)

var (
	// TODO allowed origins must be configurable
	cors     = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
	conf     *config.Config
	trackers *metrics.Trackers
)

type Request struct {
	Handler        interface{}
	Name           string
	CollectMetrics bool
	Metrics        *kmetrics.Metrics
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
	logName := r.Name
	collectMetrics := r.CollectMetrics

	var hHandler http.Handler

	// count the statuses of the requests
	hHandler = CountedByStatus(
		tigertonic.Marshaled(handler), logName, collectMetrics,
	)

	// add context
	hHandler = tigertonic.If(
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
		hHandler,
	)

	var registry gometrics.Registry

	if r.Metrics != nil {
		registry = r.Metrics.Registry
	}

	// add request time tracking
	hHandler = tigertonic.Timed(
		hHandler,
		logName,
		registry,
	)

	// create the final handler
	return cors.Build(hHandler)
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
