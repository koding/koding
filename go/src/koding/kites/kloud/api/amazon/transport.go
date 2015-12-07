package amazon

import (
	"net"
	"time"

	"koding/kites/kloud/httputil"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/aws/request"
	"github.com/koding/logging"
)

var transportParams = &httputil.ClientConfig{
	DialTimeout:           10 * time.Second,
	RoundTripTimeout:      60 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ResponseHeaderTimeout: 60 * time.Second,
	KeepAlive:             30 * time.Second, // a default from http.DefaultTransport
}

// NewTransport gives new resilient transport for the given ClientOptions.
func NewTransport(opts *ClientOptions) *aws.Config {
	cfg := aws.NewConfig().WithHTTPClient(httputil.NewClient(transportParams))
	retryer := &transportRetryer{
		MaxTries: 3,
	}
	if opts.Log != nil {
		retryer.Log = opts.Log.New("transport")
	}
	return request.WithRetryer(cfg, retryer)
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
	Log      logging.Logger
}

func (tr *transportRetryer) MaxRetries() int {
	return tr.MaxTries
}

func (tr *transportRetryer) ShouldRetry(r *request.Request) bool {
	doretry := isNetworkRecoverable(r.Error, true) || tr.DefaultRetryer.ShouldRetry(r)
	tr.logf("request failed (RetryCount=%d, Operation=%+v, ShouldRetry=%t): %+v",
		r.RetryCount, r.Operation, doretry, r.Error)
	return doretry
}

func (tr *transportRetryer) logf(format string, args ...interface{}) {
	if tr.Log != nil {
		tr.Log.Warning(format, args...)
	}
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
