package amazon

import (
	"koding/kites/kloud/httputil"
	"net"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/aws/request"
)

var transportParams = &httputil.ClientConfig{
	DialTimeout:           10 * time.Second,
	RoundTripTimeout:      60 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ResponseHeaderTimeout: 60 * time.Second,
	KeepAlive:             30 * time.Second, // a default from http.DefaultTransport
}

// TransportConfig configures resiliant transport used for default AWS client.
var TransportConfig *aws.Config

func init() {
	cfg := aws.NewConfig().WithHTTPClient(httputil.NewClient(transportParams))
	TransportConfig = request.WithRetryer(cfg, transportRetryer{MaxTries: 3})
}

// transportRetryer provides strategy for deciding whether we should retry a request.
//
// In general, the criteria for retrying a request are described here:
//
//   http://docs.aws.amazon.com/general/latest/gr/api-retries.html
//
// ShouldRetry gives true when the underlying error was either temporary or
// caused by a timeout.
type transportRetryer struct {
	client.DefaultRetryer
	MaxTries int
}

func (tr transportRetryer) MaxRetries() int {
	return tr.MaxTries
}

func (tr transportRetryer) ShouldRetry(r *request.Request) bool {
	return isNetworkRecoverable(r.Error, true) || tr.DefaultRetryer.ShouldRetry(r)
}

func isNetworkRecoverable(err error, initial bool) bool {
	switch e := err.(type) {
	case awserr.Error:
		if !initial {
			return false
		}
		return isNetworkRecoverable(e.OrigErr(), false)
	case net.Error:
		return e.Temporary() || e.Timeout()
	default:
		return false
	}
}
