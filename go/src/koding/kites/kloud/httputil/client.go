package httputil

import (
	"net"
	"net/http"
	"time"

	"koding/kites/common"

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

var httpClient = NewClient(&ClientConfig{
	DialTimeout:           10 * time.Second,
	RoundTripTimeout:      60 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ResponseHeaderTimeout: 60 * time.Second,
	KeepAlive:             30 * time.Second, // a default from http.DefaultTransport
})

var httpDebugClient = NewClient(&ClientConfig{
	DialTimeout:           10 * time.Second,
	RoundTripTimeout:      60 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ResponseHeaderTimeout: 60 * time.Second,
	KeepAlive:             30 * time.Second, // a default from http.DefaultTransport
	Log:                   common.NewLogger("dialer", true),
	TraceLeakedConn:       true,
})

// DefaultClient gives a global http.Client usable for performing short-lived
// REST requests.
//
// It it not usable for streaming APIs.
func DefaultClient(debug bool) *http.Client {
	if debug {
		return httpDebugClient
	}

	return httpClient
}
