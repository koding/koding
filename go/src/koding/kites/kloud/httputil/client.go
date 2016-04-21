package httputil

import (
	"net"
	"net/http"
	"time"

	"github.com/koding/logging"
)

// ClientConfig describes underlying TCP transport properties of the HTTP client.
type ClientConfig struct {
	// Client options.
	DialTimeout           time.Duration  // maximum time spend dialing the remote endpoint
	RoundTripTimeout      time.Duration  // maximum time awaiting full request+response
	TLSHandshakeTimeout   time.Duration  // maximum time awaiting TLS handshake
	ResponseHeaderTimeout time.Duration  // maximum time awaiting response headers
	KeepAlive             time.Duration  // TCP KeepAlive interval for long-running connections
	MaxIdleConnsPerHost   int            // maximum idle connections per host
	Jar                   http.CookieJar // a cookie jar for http.Client

	// Dialer options.
	Director        func(net.Conn) // when non-nil called by dialer after each successful Dial
	TickInterval    time.Duration  // interval between connection checks
	Log             logging.Logger // used for logging
	TraceLeakedConn bool           // makes Dialer trace connections and print stack trace for each leaked
}

// NewClient gives new HTTP client created for the given configuration.
//
// If cfg is nil, it returns http.DefaultClient.
func NewClient(cfg *ClientConfig) *http.Client {
	if cfg == nil {
		return http.DefaultClient
	}
	return &http.Client{
		Timeout: cfg.RoundTripTimeout,
		Jar:     cfg.Jar,
		Transport: &http.Transport{
			Proxy: http.ProxyFromEnvironment,
			ResponseHeaderTimeout: cfg.ResponseHeaderTimeout,
			TLSHandshakeTimeout:   cfg.TLSHandshakeTimeout,
			MaxIdleConnsPerHost:   cfg.MaxIdleConnsPerHost,
			Dial:                  NewDialer(cfg).Dial,
		},
	}
}
