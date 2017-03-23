package httputil

import (
	"net"
	"net/http"
	"time"

	"github.com/koding/kite/config"
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
	MaxIdleConns          int            // maximum idle connections
	IdleConnTimeout       time.Duration  // maximmum time an idle client will be kept in the pool
	ExpectContinueTimeout time.Duration  // maximum time to wait for server's reply in case of 100
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
			MaxIdleConns:          cfg.MaxIdleConns,
			DialContext:           NewDialer(cfg).DialContext,
		},
	}
}

func New(timeout time.Duration, debug bool) *http.Client {
	cfg := &ClientConfig{
		DialTimeout:           10 * time.Second,
		RoundTripTimeout:      timeout,
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout: 60 * time.Second,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
		KeepAlive:             30 * time.Second, // a default from http.DefaultTransport
		Jar:                   config.CookieJar,
		TraceLeakedConn:       debug,
	}

	if debug {
		cfg.Log = logging.NewCustom("httputil", true)
	}

	return NewClient(cfg)
}

var (
	client         = New(60*time.Second, false) // AWS API, Softlayer API etc.
	clientDebug    = New(60*time.Second, true)  // like above but with debug on
	xhrClient      = New(0, false)              // kite XHR polling
	xhrClientDebug = New(0, true)               // like above but with debug on
)

// Client gives a global http.Client usable for performing short-lived
// REST requests.
//
// It it not usable for kite XHR connections due to non-zero round-trip timeout.
func Client(debug bool) *http.Client {
	if debug {
		return clientDebug
	}

	return client
}

// ClientXHR gives a global http.Client usable for performing long-lived
// requests.
func ClientXHR(debug bool) *http.Client {
	if debug {
		return xhrClientDebug
	}

	return xhrClient
}
