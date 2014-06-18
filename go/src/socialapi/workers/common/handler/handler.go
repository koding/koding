package handler

import (
	"net/http"

	"github.com/rcrowley/go-tigertonic"
)

var (
	// TODO allowed origins must be configurable
	cors = tigertonic.NewCORSBuilder().AddAllowedOrigins("*")
)

func Wrapper(handler interface{}, logName string) http.Handler {
	return cors.Build(
		tigertonic.Timed(
			tigertonic.Marshaled(handler),
			logName,
			nil,
		))
}
