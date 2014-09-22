package api

import (
	"socialapi/workers/common/handler"

	"github.com/rcrowley/go-tigertonic"
)

func InitHandlers(mux *tigertonic.TrieServeMux) *tigertonic.TrieServeMux {
	//----------------------------------------------------------
	// Subscriptions
	//----------------------------------------------------------

	mux.Handle("POST", "/payments/subscribe", handler.Wrapper(
		handler.Request{
			Handler: Subscribe,
			Name:    "payment-subsrcibe",
		},
	))

	mux.Handle("GET", "/payments/subscriptions/{accountId}", handler.Wrapper(
		handler.Request{
			Handler: SubscriptionRequest,
			Name:    "payment-subscriptions",
		},
	))

	//----------------------------------------------------------
	// Invoices
	//----------------------------------------------------------

	mux.Handle("GET", "/payments/invoices/{accountId}", handler.Wrapper(
		handler.Request{
			Handler: InvoiceRequest,
			Name:    "payment-invoices",
		},
	))

	//----------------------------------------------------------
	// CreditCard
	//----------------------------------------------------------

	mux.Handle("GET", "/payments/creditcard/{accountId}", handler.Wrapper(
		handler.Request{
			Handler: CreditCardRequest,
			Name:    "payment-creditcard",
		},
	))

	mux.Handle("POST", "/payments/creditcard/update", handler.Wrapper(
		handler.Request{
			Handler: UpdateCreditCardRequest,
			Name:    "payment-updatecreditcard",
		},
	))

	//----------------------------------------------------------
	// Stripe webhook
	//----------------------------------------------------------
	mux.Handle("POST", "/payments/stripe/webhook", handler.Wrapper(
		handler.Request{
			Handler: StripeWebhook,
			Name:    "payment-stripewebhook",
		},
	))

	return mux
}
