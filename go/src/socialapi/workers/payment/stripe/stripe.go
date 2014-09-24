package stripe

import (
	"errors"

	stripe "github.com/stripe/stripe-go"
)

var (
	ProviderName = "stripe"
)

func InitializeClientKey(key string) {
	stripe.Key = key
}

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
