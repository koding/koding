package api

import (
	"github.com/rcrowley/go-tigertonic"
	"net/http"
)

var (
	// TODO allowed origins must be configurable
	cors = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
)

func HandlerWrapper(handler interface{}, logName string) http.Handler {
	return cors.Build(
		tigertonic.Timed(
			tigertonic.Marshaled(handler),
			logName,
			nil,
		))
}
