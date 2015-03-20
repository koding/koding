package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/metrics"
)

func AddHandlers(m *mux.Mux, metric *metrics.Metrics) {
	//----------------------------------------------------------
	// Subscriptions
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:        Subscribe,
			Name:           "payment-subsrcibe",
			Type:           handler.PostRequest,
			Endpoint:       "/payments/subscribe",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  SubscriptionRequest,
			Name:     "payment-subscriptions",
			Type:     handler.GetRequest,
			Endpoint: "/payments/subscriptions",
			Metrics:  metric,
		})

	//----------------------------------------------------------
	// Customers
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:  GetCustomersRequest,
			Name:     "payment-getcustomer",
			Type:     handler.GetRequest,
			Endpoint: "/payments/customers",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  DeleteCustomerRequest,
			Name:     "payment-deletecustomer",
			Type:     handler.DeleteRequest,
			Endpoint: "/payments/customers/{accountId}",
			Metrics:  metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:  ExpireCustomerRequest,
			Name:     "payment-expirecustomer",
			Type:     handler.PostRequest,
			Endpoint: "/payments/customers/{accountId}/expire",
			Metrics:  metric,
		})

	//----------------------------------------------------------
	// Invoices
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:  InvoiceRequest,
			Name:     "payment-invoices",
			Type:     handler.GetRequest,
			Endpoint: "/payments/invoices/{accountId}",
			Metrics:  metric,
		})

	//----------------------------------------------------------
	// CreditCard
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:        CreditCardRequest,
			Name:           "payment-creditcard",
			Type:           handler.GetRequest,
			Endpoint:       "/payments/creditcard/{accountId}",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        UpdateCreditCardRequest,
			Name:           "payment-updatecreditcard",
			Type:           handler.PostRequest,
			Endpoint:       "/payments/creditcard/update",
			CollectMetrics: true,
			Metrics:        metric,
		})

	//----------------------------------------------------------
	// Paypal
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:        PaypalSuccess,
			Name:           "payment-paypalsuccess",
			Type:           handler.PostRequest,
			Endpoint:       "/payments/paypal/return",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        PaypalCancel,
			Name:           "payment-paypalcancel",
			Type:           handler.PostRequest,
			Endpoint:       "/payments/paypal/cancel",
			CollectMetrics: true,
			Metrics:        metric,
		})

	m.AddHandler(
		handler.Request{
			Handler:        PaypalGetToken,
			Name:           "payment-paypalgettoken",
			Type:           handler.GetRequest,
			Endpoint:       "/payments/paypal/token",
			CollectMetrics: true,
			Metrics:        metric,
		})
}
