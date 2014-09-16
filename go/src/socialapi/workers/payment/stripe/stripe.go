package stripe

import (
	stripe "github.com/stripe/stripe-go"
)

var (
	ProviderName = "stripe"
)

func init() {
	stripe.Key = "sk_test_VSkGDktXmmxl0MvXajOBxYGm"
}
