package sl

import (
	"net/http"
	"time"

	"koding/kites/kloud/httputil"
)

var transportParams = &httputil.ClientConfig{
	DialTimeout:           10 * time.Second,
	RoundTripTimeout:      60 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ResponseHeaderTimeout: 60 * time.Second,
	KeepAlive:             30 * time.Second,
}

// NewClient gives custom HTTP client for Softlayer API.
func NewClient() *http.Client {
	return httputil.NewClient(transportParams)
}
