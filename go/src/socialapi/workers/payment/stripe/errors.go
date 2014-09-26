package stripe

import (
	"errors"

	"github.com/stripe/stripe-go"
)

var (
	ErrStripePlanAlreadyExists = errors.New(`{"type":"invalid_request_error","message":"Plan already exists."}`)
)

// handlerStripeError casts error into stripe.Error if possible
// and returns builtin error with human readable string, if not
// it returns the original error.
func handleStripeError(err error) error {
	stripeError, ok := err.(*stripe.Error)
	if ok {
		return errors.New(stripeError.Msg)
	}

	return err
}
