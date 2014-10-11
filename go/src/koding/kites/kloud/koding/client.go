package koding

import (
	"net"
	"net/http"
	"time"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

var (
	// Currently all our VM's are created here
	DefaultAWSRegion = aws.USEast

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	DefaultKloudAccessKey = "AKIAIKAVWAYVSMCW4Z5A"
	DefaultKloudSecretKey = "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"

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	DefaultKodingAuth = aws.Auth{
		AccessKey: DefaultKloudAccessKey,
		SecretKey: DefaultKloudSecretKey,
	}
)

// newKodingEC2Client is returning a new default ec2 instance with a Koding
// credentials and custom client
func NewEC2Client() *ec2.EC2 {
	// include it here to because the library is not exporting it.
	var retryingTransport = &aws.ResilientTransport{
		Deadline: func() time.Time {
			return time.Now().Add(60 * time.Second)
		},
		DialTimeout: 45 * time.Second, // this is 10 seconds in original
		MaxTries:    3,
		ShouldRetry: awsRetry,
		Wait:        aws.ExpBackoff,
	}

	return ec2.NewWithClient(
		DefaultKodingAuth,
		DefaultAWSRegion,
		aws.NewClient(retryingTransport),
	)

}

// Decide if we should retry a request.  In general, the criteria for retrying
// a request is described here
// http://docs.aws.amazon.com/general/latest/gr/api-retries.html
//
// arslan: this is a slightly modified version that also includes timeouts,
// original file: https://github.com/mitchellh/goamz/blob/master/aws/client.go
func awsRetry(req *http.Request, res *http.Response, err error) bool {
	retry := false

	// Retry if there's a temporary network error or a timeout.
	if neterr, ok := err.(net.Error); ok {
		if neterr.Temporary() {
			retry = true
		}

		if neterr.Timeout() {
			retry = true
		}
	}

	// Retry if we get a 5xx series error.
	if res != nil {
		if res.StatusCode >= 500 && res.StatusCode < 600 {
			retry = true
		}
	}

	return retry
}
