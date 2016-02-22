package httputil

import (
	"net"
	"net/http"
	"time"
)

// ClientConfig describes underlying TCP transport properties of the HTTP client.
type ClientConfig struct {
	DialTimeout           time.Duration // maximum time spend dialing the remote endpoint
	RoundTripTimeout      time.Duration // maximum time awaiting full request+response
	TLSHandshakeTimeout   time.Duration // maximum time awaiting TLS handshake
	ResponseHeaderTimeout time.Duration // maximum time awaiting response headers
	KeepAlive             time.Duration // TCP KeepAlive interval for long-running connections
}

// NewClient gives new HTTP client created for the given configuration.
//
// If cfg is nil, it returns http.DefaultClient.
func NewClient(cfg *ClientConfig) *http.Client {
	if cfg == nil {
		return http.DefaultClient
	}
	return &http.Client{
		Transport: &http.Transport{
			Proxy: http.ProxyFromEnvironment,
			ResponseHeaderTimeout: cfg.ResponseHeaderTimeout,
			Dial: (&net.Dialer{
				Timeout:   cfg.DialTimeout,
				KeepAlive: cfg.KeepAlive,
			}).Dial,
			TLSHandshakeTimeout: cfg.TLSHandshakeTimeout,
		},
		Timeout: cfg.RoundTripTimeout,
	}
}
