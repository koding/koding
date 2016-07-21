package tigertonic

import (
	"fmt"
	"net/http"
	"strings"
	"time"
)

const ONE_YEAR_IN_HOURS = time.Hour * 24 * 365

// CacheControl is an http.Handler that sets cache headers.
type CacheControl struct {
	options CacheOptions
	handler http.Handler
}

// Cached returns an http.Handler that sets appropriate Cache headers on
// the outgoing response and passes requests to a wrapped http.Handler.
func Cached(handler http.Handler, o CacheOptions) *CacheControl {
	return &CacheControl{
		handler: handler,
		options: o,
	}
}

// ServeHTTP sets the header and passes the request and response to the
// wrapped http.Handler
func (c *CacheControl) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	c.handler.ServeHTTP(w, r)
	if w.Header().Get("Cache-Control") == "" {
		w.Header().Set("Cache-Control", c.options.String())
	}
}

// These set the relevant headers in the response per
// http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html
type CacheOptions struct {
	Immutable       bool
	IsPrivate       bool
	NoCache         bool
	NoStore         bool
	NoTransform     bool
	MustRevalidate  bool
	ProxyRevalidate bool
	MaxAge          time.Duration
	SharedMaxAge    time.Duration
}

func (o CacheOptions) String() string {
	elements := make([]string, 0)
	if o.Immutable {
		o.MaxAge = ONE_YEAR_IN_HOURS
	}

	if o.IsPrivate {
		elements = append(elements, "private")
	}

	if o.NoCache {
		elements = append(elements, "no-cache")
	}

	if o.NoStore {
		elements = append(elements, "no-store")
	}

	if o.NoTransform {
		elements = append(elements, "no-transform")
	}

	if o.MustRevalidate {
		elements = append(elements, "must-revalidate")
	}

	if o.ProxyRevalidate {
		elements = append(elements, "proxy-revalidate")
	}

	if o.MaxAge != 0 {
		elements = append(elements, fmt.Sprintf("max-age=%.0f", o.MaxAge.Seconds()))
	}

	if o.SharedMaxAge != 0 {
		elements = append(elements, fmt.Sprintf("s-maxage=%.0f", o.SharedMaxAge.Seconds()))
	}

	return strings.Join(elements, ", ")
}
