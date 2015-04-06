package koding

import (
	"time"

	"github.com/cenkalti/backoff"
	"github.com/mitchellh/goamz/ec2"
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
	ec2Error, ok := err.(*ec2.Error)
	if !ok {
		return false // return back if it's not an ec2.Error type
	}

	fallbackErrors := []string{
		"InsufficientInstanceCapacity",
		"InstanceLimitExceeded",
	}

	// check wether the incoming error code is one of the fallback
	// errors
	for _, fbErr := range fallbackErrors {
		if ec2Error.Code == fbErr {
			return true
		}
	}

	// return for non fallback errors, because we can't do much
	// here and probably it's need a more tailored solution
	return false
}

func isAddressNotFoundError(err error) bool {
	ec2Error, ok := err.(*ec2.Error)
	if !ok {
		return false
	}

	return ec2Error.Code == "InvalidAddress.NotFound"
}
