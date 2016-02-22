package koding

import (
	"time"

	"koding/kites/kloud/api/amazon"

	"github.com/cenkalti/backoff"
)

// retry is a function who calls the given function until it returns a nil
// error for the given totalDuration. The retry mechanism is based on the
// exponential backoff algorithm. If the totalDuration pass, the last error
// from the function is returned.
func retry(totalDuration time.Duration, fn func() error) error {
	opts := backoff.NewExponentialBackOff()

	// don't start immediately, take it slow
	opts.InitialInterval = time.Duration(time.Second * 2)
	opts.MaxElapsedTime = totalDuration

	return backoff.Retry(fn, opts)
}

func isCapacityError(err error) bool {
	return amazon.IsErrCode(err, "InsufficientInstanceCapacity", "InstanceLimitExceeded")
}
