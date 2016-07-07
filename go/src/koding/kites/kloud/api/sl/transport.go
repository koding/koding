package sl

import (
	"net/http"
	"time"

	"koding/httputil"
)

var transportParams = &httputil.ClientConfig{
	DialTimeout:           20 * time.Second,
	RoundTripTimeout:      120 * time.Second,
	TLSHandshakeTimeout:   20 * time.Second,
	ResponseHeaderTimeout: 120 * time.Second,
	KeepAlive:             60 * time.Second,
}

// NewClient gives custom HTTP client for Softlayer API.
func NewClient() *http.Client {
	return httputil.NewClient(transportParams)
}
