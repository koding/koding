package api

import (
	"socialapi/workers/common/handler"

	"github.com/koding/metrics"
	"github.com/rcrowley/go-tigertonic"
)

func InitHandlers(mux *tigertonic.TrieServeMux, metrics *metrics.Metrics) *tigertonic.TrieServeMux {
	//----------------------------------------------------------
	// Subscriptions
	//----------------------------------------------------------

	mux.Handle("POST", "/payments/subscribe", handler.Wrapper(
		handler.Request{
			Handler:        Subscribe,
			Name:           "payment-subsrcibe",
			CollectMetrics: true,
			Metrics:        metrics,
		},
	))

	mux.Handle("GET", "/payments/subscriptions/{accountId}", handler.Wrapper(
		handler.Request{
			Handler: SubscriptionRequest,
			Name:    "payment-subscriptions",
			Metrics: metrics,
		},
	))

	//----------------------------------------------------------
	// Invoices
	//----------------------------------------------------------

	mux.Handle("GET", "/payments/invoices/{accountId}", handler.Wrapper(
		handler.Request{
			Handler: InvoiceRequest,
			Name:    "payment-invoices",
			Metrics: metrics,
		},
	))

	//----------------------------------------------------------
	// CreditCard
	//----------------------------------------------------------

	mux.Handle("GET", "/payments/creditcard/{accountId}", handler.Wrapper(
		handler.Request{
			Handler:        CreditCardRequest,
			Name:           "payment-creditcard",
			CollectMetrics: true,
			Metrics:        metrics,
		},
	))

	mux.Handle("POST", "/payments/creditcard/update", handler.Wrapper(
		handler.Request{
			Handler:        UpdateCreditCardRequest,
			Name:           "payment-updatecreditcard",
			CollectMetrics: true,
			Metrics:        metrics,
		},
	))

	//----------------------------------------------------------
	// Stripe webhook
	//----------------------------------------------------------
	mux.Handle("POST", "/payments/stripe/webhook", handler.Wrapper(
		handler.Request{
			Handler: StripeWebhook,
			Name:    "payment-stripewebhook",
			Metrics: metrics,
		},
	))

	return mux
}
