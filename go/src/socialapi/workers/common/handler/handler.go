package handler

import (
	"net/http"
	"socialapi/models"

	"github.com/rcrowley/go-tigertonic"
)

var (
	// TODO allowed origins must be configurable
	cors = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
)

func Wrapper(handler interface{}, logName string) http.Handler {
	return cors.Build(
		tigertonic.Timed(
			tigertonic.If(
				func(r *http.Request) (http.Header, error) {
					// this is an example
					// set group name to context
					tigertonic.Context(r).(*models.Context).GroupName = "koding"
					return nil, nil
				},
				tigertonic.Marshaled(handler)),
			logName,
			nil,
		),
	)
}
