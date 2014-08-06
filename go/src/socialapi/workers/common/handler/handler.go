package handler

import (
	"net/http"

	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/metrics"

	"github.com/rcrowley/go-tigertonic"
)

var (
	// TODO allowed origins must be configurable
	cors = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
)

func Wrapper(handler interface{}, logName string, collectMetrics bool) http.Handler {
	return cors.Build(
		tigertonic.Timed(
			tigertonic.If(
				func(r *http.Request) (http.Header, error) {
					// this is an example
					// set group name to context
					tigertonic.Context(r).(*models.Context).GroupName = "koding"
					return nil, nil
				},
				CountedByStatus(
					tigertonic.Marshaled(handler), logName, collectMetrics,
				),
			),
			logName,
			nil,
		),
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
		conf := config.MustGet()
		trackers := metrics.InitTrackers(
			metrics.NewMixpanelTracker(conf.Analytics.MixpanelToken),
		)

		if c.collectMetrics && conf.Analytics.Enabled {
			trackers.Track(c.name)
		}
	}
}

func CountedByStatus(handler http.Handler, name string, collectMetrics bool) *CounterByStatus {
	return &CounterByStatus{
		name:           name,
		handler:        handler,
		collectMetrics: collectMetrics,
	}
}
