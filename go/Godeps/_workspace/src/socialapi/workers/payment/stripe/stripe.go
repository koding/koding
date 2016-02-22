package stripe

import (
	"github.com/koding/logging"
	stripe "github.com/stripe/stripe-go"
)

var (
	ProviderName = "stripe"
	Log          = logging.NewLogger("payment")
)

func InitializeClientKey(key string) {
	stripe.Key = key
}
