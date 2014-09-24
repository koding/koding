package stripe

import stripe "github.com/stripe/stripe-go"

var (
	ProviderName = "stripe"
)

func InitializeClientKey(key string) {
	stripe.Key = key
}
